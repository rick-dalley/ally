import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/screens/physical_health.dart';
import 'package:triage/screens/prescription_screen.dart';
import 'package:triage/screens/questionnaires_screen.dart';
import 'package:triage/screens/tests_screen.dart';
import 'package:triage/widgets/carbon_style_action_tile.dart';

import '../app_theme.dart';
import '../classes/patient.dart';
import 'immunization_screen.dart';
import 'observation.dart';

class MedicalProfileScreen extends StatefulWidget {
  final Patient householdMember;

  const MedicalProfileScreen({super.key, required this.householdMember});

  @override
  State<MedicalProfileScreen> createState() => MedicalProfileScreenState();
}

class MedicalProfileScreenState extends State<MedicalProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // HEADER AREA (Fixed)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "PROFILE",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.lightTheme.primaryColorDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

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
                  CarbonActionTile(
                    title: "Existing Medical Conditions",
                    subTitle: "Review & Update",
                    icon: Symbols.diagnosis_sharp,
                    iconSize: Size(40.0, 40.0),
                    outlineIcon: Symbols.diagnosis_sharp,
                    onTap: () => _launchPhysicalHealthChecklist(context, widget.householdMember.patientUuid),
                  ),
                  CarbonActionTile(
                    title: "Medical Diary",
                    subTitle: "Observations about my health journey",
                    icon: Symbols.clinical_notes_sharp,
                    iconSize: Size(40.0, 40.0),
                    outlineIcon: Symbols.clinical_notes_sharp,
                    onTap: () => _launchObservationsModal(context),
                  ),
                  CarbonActionTile(
                    title: "Immunizations",
                    subTitle: "Immunization shots recommended in my locality",
                    icon: Symbols.vaccines_sharp,
                    iconSize: Size(40.0, 40.0),
                    outlineIcon: Symbols.vaccines_sharp,
                    onTap: () => _launchImmunizationModal(context, widget.householdMember),
                  ),
                  CarbonActionTile(
                    title: "Prescriptions",
                    subTitle: "Medications that have been prescribed for you",
                    icon: Symbols.medication_sharp,
                    iconSize: Size(40.0, 40.0),
                    outlineIcon: Symbols.medication_sharp,
                    onTap: () => launchMedicationScreen(patient: widget.householdMember),
                  ),
                  CarbonActionTile(
                    title: "Tests",
                    subTitle: "Medical testing and lab work",
                    icon: Symbols.lab_panel,
                    iconSize: Size(40.0, 40.0),
                    outlineIcon: Symbols.lab_panel,
                    onTap: () => launchTestsScreen(patient: widget.householdMember),
                  ),
                  CarbonActionTile(
                    title: "Mental Wellness Questionnaires",
                    subTitle: "Questionnaires to help your care giver assess your current mental health",
                    icon: Symbols.ballot_sharp,
                    iconSize: Size(40.0, 40.0),
                    outlineIcon: Symbols.ballot_sharp,
                    onTap: () => launchQuestionnairesScreen(patient: widget.householdMember),
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
      backgroundColor: AppTheme.clinicalWhite,
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

  void launchTestsScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.clinicalWhite,
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

  void launchQuestionnairesScreen({required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.clinicalWhite,
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
            Expanded(child: QuestionnairesScreen(patient: widget.householdMember)),
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
      backgroundColor: AppTheme.clinicalWhite,
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
              child: PhysicalHealthAssessment(
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

  Future<void> _launchObservationsModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Ensure the background is consistent with your theme
      backgroundColor: AppTheme.clinicalWhite,
      // Explicitly set to zero to override the default Material rounding
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Container(
          // Constrain height if it's not a full-screen sheet
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: AppTheme.clinicalWhite,
            borderRadius: BorderRadius.zero, // Sharp corners
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pull bar handle indicator
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                    ),
                    // Dismiss Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Symbols.close, color: Colors.grey, size: 22),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: ObservationScreen(patientUuid: widget.householdMember.patientUuid)),
            ],
          ),
        );
      },
    );
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
              color: AppColors.grey.all[0],
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
