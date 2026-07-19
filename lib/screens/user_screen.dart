import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/metric_value.dart';
import 'package:triage/classes/vitals.dart';
import 'package:triage/screens/patient_timeline_screen.dart';
import 'package:triage/widgets/blood_type_selector.dart';
import 'package:triage/widgets/carbon_style_2XL_button.dart';
import 'package:triage/widgets/current_metrics.dart';
import 'package:triage/widgets/flyout_widget.dart';
import 'package:triage/widgets/vitals_history.dart';
import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/carbon_style_constants.dart';
import '../classes/database_manager.dart';
import '../classes/flyable.dart';
import '../classes/listable.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../classes/patient_pain.dart';
import '../classes/patient_sentiment.dart';
import '../widgets/body_metrics_entry_widget.dart';
import '../widgets/carbon_style_expander.dart';
import 'body_screen.dart';
import '../widgets/carbon_style_textbox.dart';

class UserScreen extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Patient user;
  final Function(Patient) onMemberUpdate;
  final Function(Patient) onVitalsUpdate;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback? onMedsTap;

  const UserScreen({
    super.key,
    required this.user,
    this.onAssessmentsTap,
    this.onMedsTap,
    required this.onMemberUpdate(Patient patient),
    required this.onVitalsUpdate(Patient patient),
  });

  @override
  State<UserScreen> createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  late PatientController patientController;
  late PainLevel pain;
  bool _isExpanded = false;
  @override
  void initState() {
    super.initState();
    patientController = PatientController(widget.user);
    pain = widget.user.pain;
  }

  @override
  void didUpdateWidget(covariant UserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      patientController = PatientController(widget.user);
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
      backgroundColor: AppTheme.surfaceColor,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) =>
          VitalsHistoryView(patientUuid: patientUuid, vitals: vitals, onAddedVitals: refreshPatientData),
    );
  }

  void showBloodTypModal({required BuildContext context, required Patient patient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
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

  void onAboChanged(Listable abo) {
    // setState(() {
    //   Database().updateBloodType(patient.patientUuid, abo);
    // });
  }
  void onRhChanged(Listable rh) {
    // setState(() {
    //   Database().updateBloodType(patient.patientUuid, abo);
    // });
    //
  }

  @override
  Widget build(BuildContext context) {
    double bmi = MedicalMath.calculateBMI(
      weight: widget.user.weight,
      weightUom: widget.user.weightUoM,
      height: widget.user.height,
      heightUom: widget.user.heightUoM,
    );
    String bmiLabel = bmi == 0 ? "Calculate" : bmi.toStringAsFixed(1);
    Flyable sentiment = Sentiment.happy;
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
                Text(patient.firstName, style: AppTheme.carbonHeadingTextStyle),
                const SizedBox(height: 32),
                Container(
                  // color: AppTheme.surfaceColor,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.zero,
                  ),
                  // padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: Stack(
                    clipBehavior: Clip.none, // Allows the widget to draw outside its bounds
                    alignment: Alignment.centerRight,
                    children: [
                      // 1. The layout flow (Name + BloodType)
                      Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: CarbonStyle2xlButton(
                              topLabel: "Symptoms",
                              label: "I'm hurting",
                              icon: Symbols.symptoms,
                              onTap: () {
                                showSymptomsValidator(patient);
                              },
                              style: CarbonButtonStyle.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text("My mood is", style: AppTheme.carbonGhostButtonTextStyle),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        child: FlyOutWidget(
                          children: Sentiment.values,
                          style: CarbonButtonStyle.ghost,
                          onSelected: (Flyable item) {
                            setState(() {
                              sentiment = item;
                            });
                          },
                          selectedItem: sentiment.index,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Column(
                  mainAxisSize: MainAxisSize.min, // Prevents Column from taking infinite height
                  children: [
                    SizedBox(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [const SizedBox(width: 24)]),
                    ),
                    const SizedBox(height: 32),
                    CurrentMetrics(
                      title: "Recent Metrics",
                      vitals: patient.vitals,
                      barHeight: 180,
                      onTap: () {
                        showVitalsHistory(context: context, patientUuid: patientUuid, vitals: patient.vitals);
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        CarbonStyle2xlButton(
                          topLabel: "Blood Type:",
                          label: patient.bloodType.label,
                          style: CarbonButtonStyle.ghost,
                          onTap: () {
                            showBloodTypModal(context: context, patient: patient);
                          },
                          icon: Symbols.bloodtype,
                        ),
                        Spacer(),
                        CarbonStyle2xlButton(
                          topLabel: "Body Mass Index:",
                          label: bmiLabel,
                          style: CarbonButtonStyle.ghost,
                          onTap: () {
                            showMetricsEntryDialog(context: context, user: widget.user);
                          },
                          icon: Symbols.body_fat,
                        ),
                      ],
                    ),
                    CarbonStyleExpander(
                      onTap: (bool isExpanded) {
                        setState(() {
                          _isExpanded = isExpanded;
                        });
                      },
                      isExpanded: _isExpanded,
                    ),
                  ],
                ),
                if (_isExpanded)
                  Column(
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: CarbonTextEdit(label: "HEIGHT", value: patient.height.toString()),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text("(${patient.heightUoM})")),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: CarbonTextEdit(label: "WEIGHT", value: patient.weight.toString()),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Text("(${patient.weightUoM})"),
                            ),
                          ),
                        ],
                      ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  void showSymptomsValidator(Patient user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full-screen height
      useSafeArea: false, // Prevents UI overlap with status/nav bars
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height, // 90% screen height
          child: BodyOutlineScreen(patient: user), // The Stateful Widget from before
        );
      },
    );
  }

  void showMetricsEntryDialog({required BuildContext context, required Patient user}) {
    final double? cleanHeight = (user.height == 0.0) ? null : user.height;
    final double? cleanWeight = (user.weight == 0.0) ? null : user.weight;
    final String normalizedHeightUom = user.heightUoM.toLowerCase();
    final String normalizedWeightUom = user.weightUoM.toLowerCase();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Patient Metrics', style: AppTheme.carbonHeadingTextStyle),
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BodyMetricsEntryWidget(
                  height: cleanHeight,
                  weight: cleanWeight,
                  heightUom: normalizedHeightUom,
                  weightUom: normalizedWeightUom,
                  onMetricsChanged: (newWeightValue, newHeightValue) {
                    //Pop the UI instantly so the app feels snappy
                    Navigator.pop(dialogContext);
                    Future.microtask(() {
                      onMetricsChanged(newWeight: newWeightValue, newHeight: newHeightValue, patient: widget.user);
                    });
                  },
                ),
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

  void onMetricsChanged({double? newHeight, double? newWeight, required Patient patient}) async {
    final String patientUuid = patient.patientUuid;
    if (patientUuid.isEmpty) return;

    if (newHeight != null && newHeight > 0) {
      final MetricValue? lastHeightMetric = await DatabaseManager().getLatestMetric(patientUuid, 'height');

      if (lastHeightMetric == null || lastHeightMetric.value != newHeight) {
        await DatabaseManager().insertPatientMetric(patientUuid, newHeight, 'height');
        setState(() {
          patient.height = newHeight;
        });
      }
    }

    // --- HANDLE WEIGHT FILTER ---
    if (newWeight != null && newWeight > 0) {
      final MetricValue? lastWeightMetric = await DatabaseManager().getLatestMetric(patientUuid, 'weight');
      bool shouldWriteWeight = true;

      if (lastWeightMetric != null) {
        final Duration timeSinceLastLog = DateTime.now().difference(lastWeightMetric.recorded);
        if (lastWeightMetric.value == newWeight && timeSinceLastLog.inHours < 23) {
          shouldWriteWeight = false;
        }
      }

      if (shouldWriteWeight) {
        await DatabaseManager().insertPatientMetric(patientUuid, newWeight, 'weight');
        setState(() {
          patient.weight = newWeight;
        });
      }
    }
  }
}
