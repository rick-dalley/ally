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
import 'blood_type_tile.dart';
import 'body_metrics_widget.dart';
import 'carbon_button_compact.dart';
import 'carbon_style_textbox.dart';

class UserCard extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Patient householdMember;
  final Function(Patient) onMemberUpdate;
  final Function(Patient) onVitalsUpdate;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback? onMedsTap;

  const UserCard({
    super.key,
    required this.householdMember,
    this.onAssessmentsTap,
    this.onMedsTap,
    required this.onMemberUpdate(Patient patient),
    required this.onVitalsUpdate(Patient patient),
  });

  @override
  State<UserCard> createState() => UserCardState();
}

class UserCardState extends State<UserCard> {
  late PatientController patientController;
  late Sentiment sentiment;
  bool _isExpanded = false;
  @override
  void initState() {
    super.initState();
    patientController = PatientController(widget.householdMember);
    sentiment = widget.householdMember.sentiment;
  }

  @override
  void didUpdateWidget(covariant UserCard oldWidget) {
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
      widget.onMemberUpdate(patientController.patient);
    }
  }

  void updateAcuity() {
    widget.onMemberUpdate(patientController.patient);
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

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width - 88;

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

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replace your existing Container child: Row(...) block with this:
                Container(
                  decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.zero),
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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.greyDepth),
                          ),
                          const Spacer(),

                          const SizedBox(width: 72), // Reserve space for the SentimentWidget
                        ],
                      ),

                      // The SentimentWidget "floats" on top, ignoring the Row
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
                const SizedBox(height: 24),
                Column(
                  mainAxisSize: MainAxisSize.min, // Prevents Column from taking infinite height
                  children: [
                    SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: BloodTypeTile(
                              bloodType: patient.bloodType,
                              onTap: () {
                                showBloodTypModal(context: context, patient: patient);
                              },
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: CarbonCompactButton(
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
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    CurrentMetrics(
                      title: "Recent Metrics",
                      vitals: patient.vitals,
                      barHeight: 120,
                      onTap: () {
                        showVitalsHistory(context: context, patientUuid: patientUuid, vitals: patient.vitals);
                      },
                    ),
                    SizedBox(height: 32),
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text(
                              "Clerical Details",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Icon(
                              _isExpanded ? Symbols.keyboard_arrow_up : Symbols.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                CarbonTextEdit(
                  label: 'Provincial Health #:',
                  helperText: "Enter your government issued health identification",
                  value: _formatPHN(patient.phn.toString()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: CarbonTextEdit(label: "Born:", value: patient.formattedDateOfBirth),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text("(${patient.age} yrs)")),
                  ],
                ),
                SizedBox(height: 16),
                BodyMetricsWidget(patient: patient),
                SizedBox(height: 16),
                CarbonTextEdit(label: "CONTACT:", value: patient.contactName),
                CarbonTextEdit(label: "PHONE:", value: patient.contactPhone),
                SizedBox(height: 16),
                CarbonTextEdit(label: "PRIMARY CAREGIVER:", value: patient.familyDoctorName),
                CarbonTextEdit(label: "PHONE:", value: patient.familyDoctorPhone),
                CarbonTextEdit(label: "PHARMACY:", value: patient.pharmacyPhone),
                CarbonTextEdit(label: "FAX:", value: patient.pharmacyFax),
              ],
            ),
          ),
        );
      },
    );
  }

  // Standard string parser to separate long sdigits into readable "#### ### ###" blocks
  String _formatPHN(String rawPhn) {
    final clean = rawPhn.replaceAll(RegExp(r'\s+'), '');
    if (clean.length == 10) {
      return "${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}";
    }
    return rawPhn; // Fallback if format differs
  }
}
