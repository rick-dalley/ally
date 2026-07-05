import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/vitals.dart';
import 'package:triage/screens/patient_timeline_screen.dart';
import 'package:triage/widgets/blood_type_selector.dart';
import 'package:triage/widgets/current_metrics.dart';
import 'package:triage/widgets/sentiment_widget.dart';
import 'package:triage/widgets/vitals_history.dart';
import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/blood_type.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../classes/patient_sentiment.dart';
import '../screens/body_screen.dart';
import '../screens/staff_screen.dart';
import 'blood_type_tile.dart';
import 'carbon_button_compact.dart';
import 'emergency_qr.dart';

class HouseholdMemberMedicalCard extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Patient householdMember;
  final Function onMemberUpdate;
  final Function onVitalsUpdate;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback? onMedsTap;

  const HouseholdMemberMedicalCard({
    super.key,
    required this.householdMember,
    this.onAssessmentsTap,
    this.onMedsTap,
    required this.onMemberUpdate({required Patient patient}),
    required this.onVitalsUpdate({required Patient patient}),
  });

  @override
  State<HouseholdMemberMedicalCard> createState() => HouseholdMemberMedicalCardState();
}

class HouseholdMemberMedicalCardState extends State<HouseholdMemberMedicalCard> {
  late PatientController patientController;
  late Sentiment sentiment;
  @override
  void initState() {
    super.initState();
    patientController = PatientController(widget.householdMember);
    sentiment = widget.householdMember.sentiment;
  }

  @override
  void didUpdateWidget(covariant HouseholdMemberMedicalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.householdMember != widget.householdMember) {
      patientController = PatientController(widget.householdMember);
    }
  }

  // A completely separate, clean async routine to fetch fresh row data
  Future<void> refreshPatientData() async {
    final dynamic result = await DatabaseManager().getPatientWithVitals(
      patientUuid: patientController.patient.patientUuid,
    );
    final Map<String, dynamic> updatedPatient = result[0];

    if (mounted) {
      // Synchronous setState execution ONLY after the data is securely sitting in memory
      setState(() {
        patientController.patient = Patient.fromJson(updatedPatient);
      });
      widget.onMemberUpdate(householdMember: patientController.patient);
    }
  }

  void updateAcuity() {
    widget.onMemberUpdate(householdMember: patientController.patient);
    setState(() {});
  }

  void showVitalsHistory({
    required BuildContext context,
    required String patientUuid,
    required CurrentVitalsRecord? vitals,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) =>
          VitalsHistoryView(patientUuid: patientUuid, vitals: vitals, onAddedVitals: refreshPatientData),
    );
  }

  void showBloodTypModal({required BuildContext context, required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => BloodTypeSelector(
        selectedAbo: patient.bloodType.abo,
        selectedRh: patient.bloodType.rh,
        onAboChanged: onAboChanged,
        onRhChanged: onRhChanged,
      ),
    );
  }

  Future<void> showTimeLineScreen(BuildContext context, String uuid, String patientName) async {
    // Assuming this returns a List or an empty list
    final actions = PatientActionFactory.instance.getActionsForPatient(uuid);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 1.0, // Near full screen
        child: PatientTimelineScreen(actions: actions, patientName: patientName),
      ),
    );
  }

  void onAboChanged(AboType? abo) {
    // setState(() {
    //   Database().updateBloodType(patient.patientUuid, abo);
    // });
  }
  void onRhChanged(RhFactor? rh) {
    // setState(() {
    //   Database().updateBloodType(patient.patientUuid, abo);
    // });
    //
  }

  void launchEmergencyQRCodeGenerator(BuildContext context, Patient householdMember) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyQRCodeView(householdMember: householdMember),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: ValueKey(patientController.patient.acuityLevel),
      listenable: patientController,
      builder: (context, _) {
        final patient = patientController.patient;
        final String patientUuid = patient.patientUuid;

        if (patient.medications > 0) {
          switch (patient.medicationSafetyAudit) {
            case MedicationSafetyAudit.interactionsNotDetected:
              break;
            case MedicationSafetyAudit.interactionsDetected:
              break;
            case MedicationSafetyAudit.auditNotPerformed:
              // Keep default theme colors
              break;
          }
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.zero,
            // side: BorderSide(color: statusColor, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replace your existing Container child: Row(...) block with this:
                Container(
                  decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(8.0)),
                  // padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: Stack(
                    clipBehavior: Clip.none, // Allows the widget to draw outside its bounds
                    alignment: Alignment.centerRight,
                    children: [
                      // 1. The layout flow (Name + BloodType)
                      Row(
                        children: [
                          Text(
                            patient.firstName,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: AppTheme.deepCharcoal),
                          ),
                          const Spacer(),
                          CarbonCompactButton(
                            label: "Symptoms",
                            icon: Symbols.symptoms,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true, // Allows full-screen height
                                useSafeArea: false, // Prevents UI overlap with status/nav bars
                                builder: (BuildContext context) {
                                  return SizedBox(
                                    height: MediaQuery.of(context).size.height, // 90% screen height
                                    child: BodyOutlineScreen(patient: patient), // The Stateful Widget from before
                                  );
                                },
                              );
                            },
                            color: Colors.red,
                          ),
                          const SizedBox(width: 72), // Reserve space for the SentimentWidget
                        ],
                      ),

                      // 2. The SentimentWidget "floats" on top, ignoring the Row
                      Positioned(
                        right: 0,
                        child: SentimentWidget(
                          selectedSentiment: sentiment,
                          painScale: sentiment.index * 2,
                          onSelected: (Sentiment newSentiment, int index) {
                            setState(() {
                              sentiment = newSentiment;
                              widget.householdMember.sentiment = sentiment;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  mainAxisSize: MainAxisSize.min, // Prevents Column from taking infinite height
                  children: [
                    SizedBox(
                      height: 148, // Increased height to comfortably fit stacked icon buttons
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.only(left: 8, right: 8, top: 8, bottom: 40.0),
                            child: BloodTypeTile(
                              bloodType: patient.bloodType,
                              onTap: () {
                                showBloodTypModal(context: context, patient: patient);
                              },
                            ),
                          ),

                          // const SizedBox(width: 16), // Add some breathing room
                          // 2. Wrap the wide widget in Expanded to take up remaining space
                          Expanded(
                            child: InkWell(
                              child: CurrentMetrics(vitals: patient.vitals, height: 108),
                              onTap: () {
                                showVitalsHistory(context: context, patientUuid: patientUuid, vitals: patient.vitals);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8, // Horizontal space between buttons
                      runSpacing: 8, // Vertical space between lines
                      alignment: WrapAlignment.start,
                      children: [
                        CarbonCompactButton(
                          label: "Medical Team",
                          icon: Symbols.stethoscope,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const StaffScreen(),
                            );
                          },
                          color: AppTheme.deepLogicViolet,
                        ),
                        CarbonCompactButton(
                          label: "Profile",
                          icon: Symbols.medical_information,
                          onTap: widget.onAssessmentsTap ?? () {},
                          color: AppTheme.deepLogicViolet,
                        ),
                        CarbonCompactButton(
                          label: "Meds",
                          icon: Symbols.medication,
                          onTap: widget.onMedsTap ?? () {},
                          color: AppTheme.deepLogicViolet,
                        ),
                        CarbonCompactButton(
                          label: 'OCR',
                          icon: Symbols.qr_code_2_add,
                          onTap: () {
                            launchEmergencyQRCodeGenerator(context, patient);
                          },
                          color: AppTheme.deepLogicViolet,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
