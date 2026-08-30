import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/domain_colors.dart';
import 'package:ally/screens/allergies_screen.dart';
import 'package:ally/screens/body_screen.dart';
import 'package:ally/screens/eye_care_screen.dart';
import 'package:ally/screens/reports_hub_screen.dart';
import 'package:ally/screens/physical_health.dart';
import 'package:ally/screens/questionnaires_screen.dart';
import 'package:ally/screens/supplies_screen.dart';
import 'package:ally/screens/tests_screen.dart';
import 'package:carbon_ui/widgets/carbon_style_action_tile.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/interfaces/flyable.dart';
import '../classes/patient.dart';
import '../classes/patient_sentiment.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_flyout_widget.dart';
import 'immunization_screen.dart';
import 'mood_check_in_screen.dart';
import 'patient_diary_screen.dart';
import 'sickness_check_in_screen.dart';
import 'therapies_screen.dart';

class MedicalProfileScreen extends StatefulWidget {
  final Patient user;

  const MedicalProfileScreen({super.key, required this.user});

  @override
  State<MedicalProfileScreen> createState() => MedicalProfileScreenState();
}

class MedicalProfileScreenState extends State<MedicalProfileScreen> {
  // Starts calm rather than a guess like "happy" — corrected to whatever the patient
  // actually last picked as soon as _loadCurrentMood resolves, below.
  Flyable sentiment = Sentiment.calm;
  bool _hasUnseenTherapies = false;
  bool _hasUnresolvedSymptomFlags = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMood();
    _checkUnseenTherapies();
    _checkUnresolvedSymptomFlags();
  }

  Future<void> _checkUnseenTherapies() async {
    final bool unseen = await DatabaseManager().hasUnseenTherapies(widget.user.patientUuid);
    if (!mounted) return;
    setState(() => _hasUnseenTherapies = unseen);
  }

  Future<void> _checkUnresolvedSymptomFlags() async {
    final rows = await DatabaseManager().getUnresolvedQuickSymptomFlags(widget.user.patientUuid);
    if (!mounted) return;
    setState(() => _hasUnresolvedSymptomFlags = rows.isNotEmpty);
  }

  // Re-checked whenever the Therapies screen is popped back to — opening it marks
  // everything viewed, so the dot needs to actually disappear on return, not just on
  // the next full screen load.
  Future<void> _openTherapies() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TherapiesScreen(patient: widget.user)),
    );
    await _checkUnseenTherapies();
  }

  Future<void> _loadCurrentMood() async {
    // Backdated to the patient's admission date, not "now" — day one of app usage
    // reads as calm even if this screen isn't opened until days later. No-ops if
    // this patient already has any mood history at all.
    await DatabaseManager().seedInitialMoodIfNeeded(widget.user.patientUuid, Sentiment.calm.index, widget.user.admitted);
    final row = await DatabaseManager().getCurrentMood(widget.user.patientUuid);
    if (row == null || !mounted) return;
    setState(() => sentiment = Sentiment.values[row['mood'] as int]);
  }

  void _recordMood(Sentiment newSentiment) {
    setState(() {
      sentiment = newSentiment;
      DatabaseManager().trackMoodChange(widget.user.patientUuid, newSentiment.index);
    });
  }

  // skipPrompt: false is the automatic path (tapping a needsCheckIn mood) — starts
  // with "do you want to write about this?" skipPrompt: true is long-press/double-tap
  // on any mood, where the gesture itself already signals wanting to write.
  void _openMoodCheckIn(Sentiment mood, {required bool skipPrompt}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            MoodCheckInScreen(mood: mood, patientUuid: widget.user.patientUuid, skipPrompt: skipPrompt),
      ),
    );
  }

  // "Sick" gets its own richer flow (symptom chips + severity, and a daily recheck
  // afterward) instead of the generic write-a-note check-in every other flagged mood
  // gets — see SicknessCheckInScreen's doc comment.
  void _openSicknessCheckIn() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SicknessCheckInScreen(patientUuid: widget.user.patientUuid),
      ),
    );
  }

  // Shown exactly once, the very first time this patient interacts with the mood
  // widget at all (any of tap/long-press/double-tap) — awaited before anything else
  // opens, so it never stacks under a check-in screen.
  Future<void> _maybeShowMoodIntro() async {
    final bool seen = await DatabaseManager().hasSeenMoodIntro(widget.user.patientUuid);
    if (seen) return;
    await DatabaseManager().markMoodIntroSeen(widget.user.patientUuid);
    if (!mounted) return;
    await _showMoodTrackingInfo(includeGestureHint: false);
  }

  // The info icon always shows this (with the gesture hint prepended); the one-time
  // intro shows it without, since a first-time patient hasn't touched anything yet.
  Future<void> _showMoodTrackingInfo({required bool includeGestureHint}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tracking your mood", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 12),
              if (includeGestureHint) ...[
                Text(
                  "You can explain how you feel about any mood by double-tapping or "
                  "long-pressing its icon.",
                  style: CarbonTheme.carbonTextStyle,
                ),
                const SizedBox(height: 12),
              ],
              Text(
                "It can be helpful for your care providers to understand changes in how "
                "you're feeling. You can track it as often as you like — and once you've "
                "tracked it for more than 5 days, we can show you the trend.",
                style: CarbonTheme.carbonTextStyle,
              ),
              const SizedBox(height: 16),
              CarbonCompactButton(
                icon: Symbols.check,
                label: "Got it",
                style: CarbonButtonStyle.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // HEADER AREA (Fixed
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Complete the details of your current health status by completing these forms and taking these assessments.",
              ),
            ),

            // SCROLLABLE LIST AREA (Flexible/Expanded)
            Expanded(
              child: ListView(
                // Use a Physics that feels natural on both iOS and Android
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                children: [
                  Container(
                    // color: AppTheme.surfaceColor,
                    decoration: BoxDecoration(
                      color: AppTheme.onPrimaryColor,
                      borderRadius: BorderRadius.zero,
                    ),
                    // padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Stack(
                      clipBehavior: Clip
                          .none, // Allows the widget to draw outside its bounds
                      alignment: Alignment.centerRight,
                      children: [
                        Row(children: [SizedBox(height: 64)]),
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Text(
                              "My mood today is ${sentiment.label}",
                              style: CarbonTheme.carbonTertiaryButtonTextStyle,
                            ),
                            IconButton(
                              icon: const Icon(Symbols.info, size: 20),
                              tooltip: "About tracking your mood",
                              onPressed: () => _showMoodTrackingInfo(includeGestureHint: true),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          child: CarbonFlyOutWidget(
                            children: Sentiment.values,
                            style: CarbonButtonStyle.tertiary,
                            onSelected: (Flyable item) async {
                              final Sentiment newSentiment = item as Sentiment;
                              _recordMood(newSentiment);
                              await _maybeShowMoodIntro();
                              if (newSentiment == Sentiment.sick) {
                                _openSicknessCheckIn();
                              } else if (newSentiment.needsCheckIn) {
                                _openMoodCheckIn(newSentiment, skipPrompt: false);
                              }
                            },
                            selectedItem: sentiment.index,
                            onItemLongPress: (Flyable item) async {
                              final Sentiment newSentiment = item as Sentiment;
                              _recordMood(newSentiment);
                              await _maybeShowMoodIntro();
                              if (newSentiment == Sentiment.sick) {
                                _openSicknessCheckIn();
                              } else {
                                _openMoodCheckIn(newSentiment, skipPrompt: true);
                              }
                            },
                            onItemDoubleTap: (Flyable item) async {
                              final Sentiment newSentiment = item as Sentiment;
                              _recordMood(newSentiment);
                              await _maybeShowMoodIntro();
                              if (newSentiment == Sentiment.sick) {
                                _openSicknessCheckIn();
                              } else {
                                _openMoodCheckIn(newSentiment, skipPrompt: true);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  CarbonActionTile(
                    title: "Existing Medical Conditions",
                    subtitle: "Review & Update",
                    icon: Symbols.diagnosis_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.diagnosis_sharp,
                    iconColor: AppDomain.conditions.color,
                    onTap: () => _launchPhysicalHealthChecklist(
                      context,
                      widget.user.patientUuid,
                    ),
                  ),
                  Stack(
                    children: [
                      CarbonActionTile(
                        title: "Therapies",
                        subtitle: "Doctor-ordered and self-directed",
                        icon: Symbols.physical_therapy,
                        iconSize: Size(32.0, 32.0),
                        outlineIcon: Symbols.physical_therapy,
                        iconColor: AppDomain.therapies.color,
                        onTap: _openTherapies,
                      ),
                      // A new therapy landed since this was last opened — same
                      // "something needs a look" signal a notification dot gives
                      // anywhere else, cleared the moment the list is actually seen.
                      if (_hasUnseenTherapies)
                        Positioned(
                          top: 12,
                          right: 24,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                  CarbonActionTile(
                    title: "Medical Diary",
                    subtitle: "Observations about my health journey",
                    icon: Symbols.clinical_notes_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.clinical_notes_sharp,
                    iconColor: AppDomain.diary.color,
                    onTap: () => launchPatientDiaryScreen(patient: widget.user),
                  ),
                  Stack(
                    children: [
                      CarbonActionTile(
                        title: "Symptoms",
                        subtitle: "Things I'm feeling",
                        icon: Symbols.symptoms,
                        iconSize: Size(32, 32),
                        iconColor: AppDomain.symptoms.color,
                        onTap: () => launchSymptoms(patient: widget.user),
                      ),
                      // A quick-pick flag came in from a watch since it was last
                      // acknowledged — same notification-dot language as Therapies,
                      // cleared only when the patient dismisses it themselves (see
                      // resolveQuickSymptomFlag's doc comment for why that's manual).
                      if (_hasUnresolvedSymptomFlags)
                        Positioned(
                          top: 12,
                          right: 24,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                  CarbonActionTile(
                    title: "Tests",
                    subtitle: "Medical testing and lab work",
                    icon: Symbols.lab_panel,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.lab_panel,
                    iconColor: AppDomain.tests.color,
                    onTap: () => launchTestsScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Reports",
                    subtitle: "Documents to share with a doctor",
                    icon: Symbols.description,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.description,
                    iconColor: AppDomain.reports.color,
                    onTap: () => launchReportsScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Allergies",
                    subtitle: "Things I react badly to",
                    icon: Symbols.allergy,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.allergy,
                    iconColor: AppDomain.allergies.color,
                    onTap: () => _launchAllergiesChecklist(
                      context,
                      widget.user.patientUuid,
                    ),
                  ),
                  CarbonActionTile(
                    title: "Eye Care",
                    subtitle: "Glasses & contacts prescriptions",
                    icon: Symbols.ophthalmology,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.ophthalmology,
                    iconColor: AppDomain.eyeCare.color,
                    onTap: () => launchEyeCareScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Supplies",
                    subtitle:
                        "Needles, swabs, test strips, and other consumables",
                    icon: Symbols.inventory_2,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.inventory_2,
                    iconColor: AppDomain.supplies.color,
                    onTap: () => launchSuppliesScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Mental Wellness Questionnaires",
                    subtitle:
                        "Questionnaires to help your care giver assess your current mental health",
                    icon: Symbols.ballot_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.ballot_sharp,
                    iconColor: AppDomain.questionnaires.color,
                    onTap: () =>
                        launchQuestionnairesScreen(patient: widget.user),
                  ),
                  // Deliberately last, not up near the top with the rest of the
                  // clinical tiles — vaccines are a subject some people have strong
                  // feelings about, and this list is scanned top-to-bottom on every
                  // visit to this screen.
                  CarbonActionTile(
                    title: "Immunizations",
                    subtitle: "Immunization shots recommended in my locality",
                    // Not vaccines_sharp — confirmed blank on Android release builds
                    // (the glyph is present in the tree-shaken font subset at the
                    // right codepoint, but doesn't paint) even though every other
                    // "_sharp" icon on this same screen renders fine.
                    icon: Symbols.vaccines,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.vaccines,
                    iconColor: AppDomain.immunizations.color,
                    onTap: () => _launchImmunizationModal(context, widget.user),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> launchSymptoms({required Patient patient}) async {
    final flags = await DatabaseManager().getUnresolvedQuickSymptomFlags(patient.patientUuid);
    if (!mounted) return;
    if (flags.isNotEmpty) {
      await _showQuickSymptomFlags(flags);
      if (!mounted) return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: carbonColorButtonTertiary,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return BodyOutlineScreen(patient: patient);
      },
    );
  }

  // Shows whatever was quick-flagged from a watch before the full entry screen opens,
  // so the patient sees why the Symptoms tile had a dot on it. Dismissing one here is
  // a separate action from actually logging it below — there's no reliable link
  // between a flag and whatever marker the patient goes on to place.
  Future<void> _showQuickSymptomFlags(List<Map<String, dynamic>> flags) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text("Flagged from your watch"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final flag in flags)
                    ListTile(
                      title: Text(flag['label'] as String),
                      trailing: IconButton(
                        icon: const Icon(Symbols.check),
                        tooltip: "I've dealt with this",
                        onPressed: () async {
                          await DatabaseManager().resolveQuickSymptomFlag(flag['id'] as String);
                          flags.remove(flag);
                          setDialogState(() {});
                          if (mounted) await _checkUnresolvedSymptomFlags();
                          if (flags.isEmpty && dialogContext.mounted) Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Continue to Symptoms")),
            ],
          );
        },
      ),
    );
  }

  void launchPatientDiaryScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: PatientDiaryScreen(user: patient)),
          ],
        );
      },
    );
  }

  void launchTestsScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: TestsScreen(user: patient)),
          ],
        );
      },
    );
    //
  }

  void launchReportsScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: ReportsHubScreen(patient: patient)),
          ],
        );
      },
    );
  }

  void launchEyeCareScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: EyeCareScreen(user: patient)),
          ],
        );
      },
    );
  }

  void launchSuppliesScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: SuppliesScreen(user: patient)),
          ],
        );
      },
    );
  }

  void launchQuestionnairesScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: QuestionnairesScreen(patient: widget.user)),
          ],
        );
      },
    );
  }

  Future<void> _launchAllergiesChecklist(
    BuildContext context,
    String patientUuid,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(
              child: AllergiesScreen(
                patientUuid: patientUuid,
                scrollController: ScrollController(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchPhysicalHealthChecklist(
    BuildContext context,
    String patientUuid,
  ) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.surfaceColor,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.close,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(
              child: ExistingMedicalConditionsScreen(
                patientUuid: patientUuid,
                // Pass a ScrollController if your assessment needs to manage scrolling
                scrollController: ScrollController(),
              ),
            ),
          ],
        );
      },
    );

    if (mounted && result == true) {
      setState(() {
        // completedQuestionnaires = DatabaseManager().getCompletedAssessments(patientUuid);
      });
    }
  }

  void _launchImmunizationModal(BuildContext context, Patient householdMember) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ✅ Prevents accidental drag-down dismissals on the background area
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: false, // ✅ Smooth, non-snapping fluid track
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.onPrimaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered pull bar handle indicator
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // nified Top-Right Dismiss Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  // Pass the controller into the screen
                  child: ImmunizationScreen(householdMember: householdMember),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
