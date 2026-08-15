import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/screens/allergies_screen.dart';
import 'package:triage/screens/body_screen.dart';
import 'package:triage/screens/eye_care_screen.dart';
import 'package:triage/screens/physical_health.dart';
import 'package:triage/screens/prescription_screen.dart';
import 'package:triage/screens/questionnaires_screen.dart';
import 'package:triage/screens/supplies_screen.dart';
import 'package:triage/screens/tests_screen.dart';
import 'package:triage/widgets/carbon_style_action_tile.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/flyable.dart';
import '../classes/patient.dart';
import '../classes/patient_sentiment.dart';
import '../widgets/carbon_button_compact.dart';
import '../widgets/carbon_flyout_widget.dart';
import '../widgets/carbon_style_textbox.dart';
import 'immunization_screen.dart';
import 'patient_diary_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCurrentMood();
  }

  Future<void> _loadCurrentMood() async {
    final row = await DatabaseManager().getCurrentMood(widget.user.patientUuid);
    if (row != null) {
      if (!mounted) return;
      setState(() => sentiment = Sentiment.values[row['mood'] as int]);
      return;
    }
    // First time this patient has ever opened this screen — seed a real starting
    // row at calm rather than just holding an unsaved default in memory.
    await DatabaseManager().trackMoodChange(widget.user.patientUuid, Sentiment.calm.index);
  }

  Future<void> _askMoodReason() async {
    final controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Why do you feel ${sentiment.label.toLowerCase()}?", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 8),
              Text("Totally optional — only saved if you write something.", style: CarbonTheme.carbonHintTextStyle),
              const SizedBox(height: 16),
              CarbonTextInput(label: "Reason (optional)", controller: controller, maxLines: 3, onChanged: (_) {}),
              const SizedBox(height: 16),
              CarbonCompactButton(
                icon: Symbols.check,
                label: "Save",
                style: CarbonButtonStyle.primary,
                onTap: () => Navigator.pop(context, controller.text),
              ),
              const SizedBox(height: 8),
              CarbonCompactButton(
                icon: Symbols.close,
                label: "Cancel",
                style: CarbonButtonStyle.ghost,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
    if (reason != null && reason.trim().isNotEmpty) {
      await DatabaseManager().setMoodReason(widget.user.patientUuid, reason.trim());
    }
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
                    decoration: BoxDecoration(color: AppTheme.onPrimaryColor, borderRadius: BorderRadius.zero),
                    // padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Stack(
                      clipBehavior: Clip.none, // Allows the widget to draw outside its bounds
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
                          ],
                        ),
                        Positioned(
                          right: 0,
                          child: CarbonFlyOutWidget(
                            children: Sentiment.values,
                            style: CarbonButtonStyle.tertiary,
                            onSelected: (Flyable item) {
                              setState(() {
                                Sentiment newSentiment = item as Sentiment;
                                sentiment = newSentiment;
                                DatabaseManager().trackMoodChange(widget.user.patientUuid, sentiment.index);
                              });
                            },
                            selectedItem: sentiment.index,
                            onLongPress: _askMoodReason,
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
                    onTap: () => _launchPhysicalHealthChecklist(context, widget.user.patientUuid),
                  ),
                  CarbonActionTile(
                    title: "Medical Diary",
                    subtitle: "Observations about my health journey",
                    icon: Symbols.clinical_notes_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.clinical_notes_sharp,
                    onTap: () => launchPatientDiaryScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Immunizations",
                    subtitle: "Immunization shots recommended in my locality",
                    icon: Symbols.vaccines_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.vaccines_sharp,
                    onTap: () => _launchImmunizationModal(context, widget.user),
                  ),
                  CarbonActionTile(
                    title: "Prescriptions",
                    subtitle: "Medications that have been prescribed for you",
                    icon: Symbols.medication_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.medication_sharp,
                    onTap: () => launchMedicationScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Symptoms",
                    subtitle: "Things I'm feeling",
                    icon: Symbols.symptoms,
                    iconSize: Size(32, 32),
                    onTap: () => launchSymptoms(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Tests",
                    subtitle: "Medical testing and lab work",
                    icon: Symbols.lab_panel,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.lab_panel,
                    onTap: () => launchTestsScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Allergies",
                    subtitle: "Things I react badly to",
                    icon: Symbols.allergy,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.allergy,
                    onTap: () => _launchAllergiesChecklist(context, widget.user.patientUuid),
                  ),
                  CarbonActionTile(
                    title: "Eye Care",
                    subtitle: "Glasses & contacts prescriptions",
                    icon: Symbols.ophthalmology,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.ophthalmology,
                    onTap: () => launchEyeCareScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Supplies",
                    subtitle: "Needles, swabs, test strips, and other consumables",
                    icon: Symbols.inventory_2,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.inventory_2,
                    onTap: () => launchSuppliesScreen(patient: widget.user),
                  ),
                  CarbonActionTile(
                    title: "Mental Wellness Questionnaires",
                    subtitle: "Questionnaires to help your care giver assess your current mental health",
                    icon: Symbols.ballot_sharp,
                    iconSize: Size(32.0, 32.0),
                    outlineIcon: Symbols.ballot_sharp,
                    onTap: () => launchQuestionnairesScreen(patient: widget.user),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void launchMedicationScreen({required Patient patient}) {
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: PrescriptionScreen(patient: patient)),
          ],
        );
      },
    );
    //
  }

  void launchSymptoms({required Patient patient}) {
    showModalBottomSheet(
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
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

  Future<void> _launchAllergiesChecklist(BuildContext context, String patientUuid) async {
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(child: AllergiesScreen(patientUuid: patientUuid, scrollController: ScrollController())),
          ],
        );
      },
    );
  }

  Future<void> _launchPhysicalHealthChecklist(BuildContext context, String patientUuid) async {
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
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
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                      // nified Top-Right Dismiss Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
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
