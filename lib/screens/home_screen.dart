import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/classes/patient_action.dart';
import 'package:triage/screens/add_patients_wheel.dart';
import 'package:triage/screens/metric_dashboard_screen.dart';
import 'package:triage/screens/time_scroller.dart';
import 'package:triage/screens/user_screen.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/reminder_registry.dart';
import '../widgets/carbon_style_avatar.dart';
import '../widgets/emergency_qr.dart';
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
  }

  @override
  void dispose() {
    ReminderRegistry.instance.removeListener(_maybeShowReminders);
    _pageController.dispose();
    super.dispose();
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
        ReminderRegistry.instance.loadForPatient(patients[_currentPageIndex].patientUuid);
      }
    }
  }

  void showUserScreen({required Patient? user}) {
    if (user == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: carbonColorScaffoldBackground,
      builder: (context) => UserScreen(
        user: user,
        onMemberUpdate: (p) => updatePatient(patientIndex: _currentPageIndex, patient: p),
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
    final List<PatientAction> actions = patientActions;
    final startTime = actions.first.occurred.toUtc();
    final endTime = actions.last.until;

    return [
      MedicalProfileScreen(user: patient),
      PrescriptionScreen(patient: patient),
      MetricsDashboardScreen(
        user: patient,
        onVitalsUpdate: (p) => updatePatient(patientIndex: _currentPageIndex, patient: p),
        onMemberUpdate: (p) => updatePatient(patientIndex: _currentPageIndex, patient: p),
      ),
      ProviderRosterScreen(user: patient),
      EmergencyQRCodeView(householdMember: patient),
      TimelineScrollerWidget(actions: actions, startTime: startTime, endTime: endTime),
    ];
  }

  void _showMemberJumpList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPatientsWheel(
        familyMembers: patients,
        onDismiss: () {
          Navigator.pop(context);
        },
        onUserSelected: (dynamic patientUuid) {},
        onAddMember: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Patient? patient;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      if (patients.isNotEmpty) {
        patient = patients[_currentPageIndex];
      }
    }

    // Define clear, action-oriented titles corresponding to your 6 bottom nav tabs (_currentIndex)
    final List<String> pageActionTitles = [
      'Medical Profile',
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Action / Purpose Title
                    Text(currentActionTitle, style: CarbonTheme.carbonExpressiveTextStyle),

                    // Patient Avatar (Tap for profile, Long press for roster jump)
                    GestureDetector(
                      onLongPress: () => _showMemberJumpList(context),
                      onTap: () => showUserScreen(user: patient),
                      child: KeyedSubtree(
                        key: ValueKey(patient.name),
                        child: CarbonAvatar(user: patient),
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
                  ReminderRegistry.instance.loadForPatient(patients[index].patientUuid);
                },
                itemBuilder: (context, index) {
                  return IndexedStack(index: _currentIndex, children: _getPages(index));
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
                  color: AppTheme.lightTheme.canvasColor.withValues(alpha: 0.25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _navButton(index: 0, icon: Symbols.conditions),
                      _navButton(index: 1, icon: Symbols.medication),
                      _navButton(index: 2, icon: Symbols.health_metrics),
                      _navButton(index: 3, icon: Symbols.diversity_4),
                      _navButton(index: 4, icon: Symbols.qr_code_2),
                      _navButton(index: 5, icon: Symbols.view_object_track),
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

  Widget _navButton({required int index, required IconData icon}) {
    final bool isSelected = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? carbonColorButtonPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Icon(icon, size: 32, color: isSelected ? carbonColorButtonOnPrimary : carbonColorButtonPrimary),
      ),
    );
  }
}
