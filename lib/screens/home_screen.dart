import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:ally/screens/add_patients_wheel.dart';
import 'package:ally/screens/first_patient_wizard.dart';
import 'package:ally/screens/metric_dashboard_screen.dart';
import 'package:ally/screens/time_scroller.dart';
import 'package:ally/screens/user_screen.dart';
import '../app_theme.dart';
import '../classes/achievement_badge.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/reminder_registry.dart';
import 'package:carbon_ui/widgets/carbon_style_avatar.dart';
import '../widgets/emergency_qr.dart';
import '../widgets/avatar_ripple_effect.dart';
import '../widgets/reminder_sheet.dart';
import 'prescription_screen.dart';
import 'providers_screen.dart';
import 'medical_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _currentPageIndex = 0;
  List<Patient> patients = [];
  bool _isLoading = true;
  late PageController _pageController;
  bool _reminderSheetShowing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadPatientData();
    ReminderRegistry.instance.addListener(_maybeShowReminders);
    AchievementBadge.instance.addListener(_onAchievementBadgeChanged);
  }

  @override
  void dispose() {
    ReminderRegistry.instance.removeListener(_maybeShowReminders);
    AchievementBadge.instance.removeListener(_onAchievementBadgeChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onAchievementBadgeChanged() {
    if (mounted) setState(() {});
  }

  // Reminders float over the screen as a modal sheet rather than living inline in the
  // layout — they shouldn't push other content around or take up permanent space.
  // Fires automatically whenever the registry reports something newly due.
  void _maybeShowReminders() {
    if (_reminderSheetShowing || !mounted) return;
    if (ReminderRegistry.instance.due.isEmpty) return;

    _reminderSheetShowing = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReminderSheet(),
    ).whenComplete(() => _reminderSheetShowing = false);
  }

  Future<void> loadPatientData() async {
    final data = await DatabaseManager().getAllPatientsWithVitals();
    if (mounted) {
      setState(() {
        patients = data.map((p) => Patient.fromJson(p)).toList();
        _isLoading = false;
      });
      if (patients.isNotEmpty) {
        ReminderRegistry.instance.loadForPatient(
          patients[_currentPageIndex].patientUuid,
        );
        AchievementBadge.instance.loadForPatient(
          patients[_currentPageIndex].patientUuid,
        );
      }
    }
  }

  void showUserScreen({required Patient? user}) {
    if (user == null) {
      return;
    }
    // isScrollControlled lifts the default ~half-screen cap; useSafeArea keeps it clear
    // of the status bar/notch. FractionallySizedBox then claims all of that available
    // height rather than shrink-wrapping to content, so the sheet always reaches the
    // safe area instead of stopping partway and forcing a drag — there's too much on
    // this screen for that, and it read as inconsistent with the rest of the app.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: carbonColorScaffoldBackground,
      builder: (context) => FractionallySizedBox(
        heightFactor: 1,
        child: UserScreen(
          user: user,
          onMemberUpdate: (p) =>
              updatePatient(patientIndex: _currentPageIndex, patient: p),
          onAddFamilyMember: _launchAddPatient,
        ),
      ),
    );
  }

  void updatePatient({required int patientIndex, required Patient patient}) {
    setState(() {
      patients[patientIndex] = patient;
    });
  }

  List<Widget> _getPages(int patientIndex) {
    final patient = patients[patientIndex];

    return [
      MedicalProfileScreen(user: patient),
      PrescriptionScreen(patient: patient),
      MetricsDashboardScreen(
        user: patient,
        onVitalsUpdate: (p) =>
            updatePatient(patientIndex: _currentPageIndex, patient: p),
        onMemberUpdate: (p) =>
            updatePatient(patientIndex: _currentPageIndex, patient: p),
      ),
      ProviderRosterScreen(user: patient),
      EmergencyQRCodeView(householdMember: patient),
      TimelineScrollerWidget(patientUuid: patient.patientUuid),
    ];
  }

  void _showMemberJumpList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // AddPatientsWheel is built assuming it owns the whole screen (its close
      // button sits at a literal top:50, the radial wheel needs real room to lay
      // out) — without isScrollControlled the sheet caps itself to a fraction of
      // the screen height by default, which was squashing all of this into a tiny
      // sliver rather than the full-screen overlay it's actually designed as.
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SizedBox.expand(
        child: AddPatientsWheel(
          familyMembers: patients,
          onDismiss: () {
            Navigator.pop(sheetContext);
          },
          onUserSelected: (patientUuid) {
            // Pop the sheet before acting on the selection — a page-change here
            // triggers a ReminderRegistry reload for the new patient, and popping
            // after a state change that can itself trigger UI (this session's
            // established "pop before refresh" rule) has repeatedly caused stuck
            // sheets elsewhere in this app when done the other way around.
            Navigator.pop(sheetContext);
            _jumpToPatient(patientUuid);
          },
          onAddMember: () {
            Navigator.pop(sheetContext);
            _launchAddPatient();
          },
        ),
      ),
    );
  }

  Future<void> _launchAddPatient() async {
    final String? newPatientUuid = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const FirstPatientWizard(addingFamilyMember: true),
      ),
    );
    if (newPatientUuid == null) return;
    await loadPatientData();
    if (mounted) _jumpToPatient(newPatientUuid);
  }

  // Tapping a family member in the jump list should land on their data with
  // whatever tab you were already on preserved — not reset to a specific screen.
  // Reuses the exact same page-change path swiping between patients already goes
  // through (PageView's onPageChanged), rather than duplicating the
  // setState/ReminderRegistry-reload logic here and risking the two paths drifting
  // apart from each other.
  void _jumpToPatient(String patientUuid) {
    final int index = patients.indexWhere((p) => p.patientUuid == patientUuid);
    if (index == -1 || index == _currentPageIndex) return;
    // Right after a setState that grew `patients` (e.g. a freshly-added family
    // member), the PageView hasn't actually rebuilt with the new itemCount on
    // screen yet — that happens next frame. Calling animateToPage immediately
    // targets a page index the live PageView doesn't have yet and silently
    // clamps to the old last page instead, landing on the wrong patient.
    // Deferring to the post-frame callback guarantees the rebuild has happened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Patient? patient;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (patients.isEmpty) {
      // A real (non-debug) install has no seeded demo data — this is the very first
      // thing a genuine user sees, since nothing else in the app has a patient to work
      // with yet.
      return FirstPatientWizard(onPatientCreated: loadPatientData);
    } else {
      patient = patients[_currentPageIndex];
    }

    // Define clear, action-oriented titles corresponding to your 6 bottom nav tabs (_currentIndex)
    // Profile tab is named for whoever's on screen — with the whole family on one
    // device (see FirstPatientWizard's "add a family member" flow), a bare "Medical
    // Profile" heading gives no cue you're looking at the wrong person's data.
    final List<String> pageActionTitles = [
      "${patient.firstName}'s Medical Profile",
      'Manage Prescriptions',
      'Review Metrics',
      'My Health Care Team',
      'Emergency QR',
      'Activity Timeline',
    ];

    final currentActionTitle = pageActionTitles[_currentIndex];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Context Bar: Page Action Title (Left) & Active Patient Avatar (Right)
            if (patient != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Action / Purpose Title
                    Text(
                      currentActionTitle,
                      style: CarbonTheme.carbonExpressiveTextStyle,
                    ),

                    // Patient Avatar (Tap for profile, Long press for roster jump) —
                    // a halo ripples out from the avatar's own edge while there's an
                    // unacknowledged trophy (see AchievementBadge), nudging them to go
                    // look at the new Trophy Case on the personal-details screen; it
                    // stops the moment they open it.
                    //
                    // The outer SizedBox pins this slot's layout footprint to the
                    // avatar's own fixed size, permanently — the ripple animates well
                    // past that size every frame, and without this the Stack would
                    // keep resizing to fit its largest current frame, visibly shoving
                    // the title text next to it back and forth. OverflowBox then lets
                    // the ripple actually paint beyond that fixed box: it reports its
                    // own size as whatever OverflowBox is told to be (the avatar size,
                    // from the SizedBox), while sizing and centering its child freely
                    // up to maxWidth/maxHeight — the standard way to let something
                    // visually overflow without it ever affecting a parent's layout,
                    // and it needs no manual x/y offset math the way Positioned would.
                    GestureDetector(
                      onLongPress: () => _showMemberJumpList(context),
                      onTap: () => showUserScreen(user: patient),
                      child: KeyedSubtree(
                        key: ValueKey(patient.name),
                        child: SizedBox(
                          width: CarbonIcons.extraExtraLarge.size.width,
                          height: CarbonIcons.extraExtraLarge.size.height,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              if (AchievementBadge.instance.hasUnacknowledged)
                                OverflowBox(
                                  maxWidth:
                                      CarbonIcons.extraExtraLarge.size.width *
                                      1.45,
                                  maxHeight:
                                      CarbonIcons.extraExtraLarge.size.height *
                                      1.45,
                                  child: IgnorePointer(
                                    child: AvatarRippleEffect(
                                      size: CarbonIcons
                                          .extraExtraLarge
                                          .size
                                          .width,
                                      color: const Color(0xFFFFA000),
                                    ),
                                  ),
                                ),
                              CarbonAvatar(name: patient.name, avatarBytes: patient.avatar),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main PageView containing the tabs
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: patients.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                  ReminderRegistry.instance.loadForPatient(
                    patients[index].patientUuid,
                  );
                  AchievementBadge.instance.loadForPatient(
                    patients[index].patientUuid,
                  );
                },
                itemBuilder: (context, index) {
                  return IndexedStack(
                    index: _currentIndex,
                    children: _getPages(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  height: 90,
                  color: AppTheme.lightTheme.canvasColor.withValues(
                    alpha: 0.25,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _navButton(
                        index: 0,
                        icon: Symbols.conditions,
                        label: "Profile",
                      ),
                      _navButton(
                        index: 1,
                        icon: Symbols.medication,
                        label: "Meds",
                      ),
                      _navButton(
                        index: 2,
                        icon: Symbols.health_metrics,
                        label: "Metrics",
                      ),
                      _navButton(
                        index: 3,
                        icon: Symbols.diversity_4,
                        label: "Providers",
                      ),
                      _navButton(
                        index: 4,
                        icon: Symbols.qr_code_2,
                        label: "Emergency",
                      ),
                      _navButton(
                        index: 5,
                        icon: Symbols.view_object_track,
                        label: "Timeline",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Icon-only nav asks a patient to remember what six glyphs mean, permanently — real
  // cognitive load for the elderly/crisis-context audience this app is built for (and,
  // Richard's own words, enough that even he pauses on it sometimes). A short label
  // under each icon removes that memory burden entirely.
  Widget _navButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected
        ? carbonColorButtonOnPrimary
        : carbonColorButtonPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? carbonColorButtonPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
