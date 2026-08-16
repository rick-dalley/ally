import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/blood_type.dart';
import 'package:triage/classes/metric_value.dart';
import 'package:triage/widgets/blood_type_selector.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_two_xl_button.dart';
import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/emergency_lock_screen.dart';
import '../classes/flyable.dart';
import '../classes/listable.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../classes/patient_pain.dart';
import '../classes/patient_sentiment.dart';
import '../widgets/body_metrics_entry_widget.dart';
import 'body_screen.dart';
import '../widgets/carbon_style_textbox.dart';
import '../widgets/trophy_case.dart';

class UserScreen extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Patient user;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback? onMedsTap;
  final Function(Patient) onMemberUpdate;

  const UserScreen({
    super.key,
    required this.user,
    this.onAssessmentsTap,
    this.onMedsTap,
    required this.onMemberUpdate(Patient patient),
  });

  @override
  State<UserScreen> createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  late PatientController patientController;
  late PainLevel pain;
  late AboType aboType;
  late RhFactor rhFactor;
  late Flyable sentiment = Sentiment.happy;

  @override
  void initState() {
    super.initState();
    aboType = widget.user.bloodType.abo;
    rhFactor = widget.user.bloodType.rh;
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

  void updateAcuity() {
    widget.onMemberUpdate(patientController.patient);
    setState(() {});
  }

  void showBloodTypModal({
    required BuildContext context,
    required Patient patient,
  }) {
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

  void onAboChanged(Listable abo) {
    setState(() {
      aboType = abo as AboType;
      DatabaseManager().updateAboType(widget.user.patientUuid, abo.index);
    });
  }

  void onRhChanged(Listable rh) {
    setState(() {
      rhFactor = rh as RhFactor;
    });
    DatabaseManager().updateRhFactor(widget.user.patientUuid, rhFactor.index);
  }

  @override
  Widget build(BuildContext context) {
    double bmi = MedicalMath.calculateBMI(
      weight: widget.user.weight,
      weightUom: widget.user.weightUoM,
      height: widget.user.height,
      heightUom: widget.user.heightUoM,
    );
    BloodType bloodType = BloodType(abo: aboType, rh: rhFactor);
    String bmiLabel = bmi == 0 ? "Calculate" : bmi.toStringAsFixed(1);
    return ListenableBuilder(
      key: ValueKey(patientController.patient.acuityLevel),
      listenable: patientController,
      builder: (context, _) {
        final patient = patientController.patient;

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
                TrophyCase(patientUuid: patient.patientUuid),
                // Replace your existing Container child: Row(...) block with this:
                Text(
                  patient.firstName,
                  style: CarbonTheme.carbonHeadingTextStyle,
                ),

                const SizedBox(height: 32),
                Column(
                  mainAxisSize: MainAxisSize
                      .min, // Prevents Column from taking infinite height
                  children: [
                    Row(
                      children: [
                        CarbonStyle2xlButton(
                          topLabel: "Blood Type",
                          label: bloodType.label,
                          width: 184,
                          style: CarbonButtonStyle.tertiary,
                          onTap: () {
                            showBloodTypModal(
                              context: context,
                              patient: patient,
                            );
                          },
                          icon: Symbols.bloodtype,
                        ),
                        Spacer(),
                        CarbonStyle2xlButton(
                          topLabel: "Body Mass Index",
                          label: bmiLabel,
                          width: 184,
                          style: CarbonButtonStyle.tertiary,
                          onTap: () {
                            showMetricsEntryDialog(
                              context: context,
                              user: widget.user,
                            );
                          },
                          icon: Symbols.body_fat,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                Column(
                  children: [
                    CarbonTextInput(
                      label: 'Provincial Health #:',
                      helperText:
                          "Enter your government issued health identification",
                      value: _formatPHN(patient.phn.toString()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: CarbonTextInput(
                            label: "Born:",
                            value: patient.formattedDateOfBirth,
                          ),
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
                          child: CarbonTextInput(
                            label: "HEIGHT",
                            value: patient.height.toString(),
                          ),
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
                          child: CarbonTextInput(
                            label: "WEIGHT",
                            value: patient.weight.toString(),
                          ),
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
                    CarbonTextInput(
                      label: "CONTACT:",
                      value: patient.contactName,
                    ),
                    SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PHONE:",
                      value: patient.contactPhone,
                    ),
                    SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PRIMARY CAREGIVER:",
                      value: patient.familyDoctorName,
                    ),
                    SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PHONE:",
                      value: patient.familyDoctorPhone,
                    ),
                    SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PHARMACY:",
                      value: patient.pharmacyPhone,
                    ),
                    SizedBox(height: 16),
                    CarbonTextInput(label: "FAX:", value: patient.pharmacyFax),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  "Emergency Access",
                  style: CarbonTheme.carbonLabelTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  Platform.isIOS
                      ? "Save your emergency QR as a Lock Screen wallpaper "
                            "so responders can see it without unlocking your "
                            "phone."
                      : "Show your emergency QR directly on the lock screen, "
                            "without unlocking your phone, for responders.",
                  style: CarbonTheme.carbonHelperTextStyle,
                ),
                const SizedBox(height: 12),
                CarbonButton(
                  label: Platform.isIOS
                      ? "Set Emergency QR as Lock Screen"
                      : "Emergency Lock Screen Access",
                  icon: Symbols.emergency,
                  style: CarbonButtonStyle.danger,
                  onPressed: () =>
                      EmergencyLockScreen.present(context, patient),
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
          child: BodyOutlineScreen(
            patient: user,
          ), // The Stateful Widget from before
        );
      },
    );
  }

  void showMetricsEntryDialog({
    required BuildContext context,
    required Patient user,
  }) {
    final double? cleanHeight = (user.height == 0.0) ? null : user.height;
    final double? cleanWeight = (user.weight == 0.0) ? null : user.weight;
    final String normalizedHeightUom = user.heightUoM.toLowerCase();
    final String normalizedWeightUom = user.weightUoM.toLowerCase();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Update Patient Metrics',
            style: AppTheme.defaultHeadingStyle,
          ),
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
                      onMetricsChanged(
                        newWeight: newWeightValue,
                        newHeight: newHeightValue,
                        patient: widget.user,
                      );
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

  void onMetricsChanged({
    double? newHeight,
    double? newWeight,
    required Patient patient,
  }) async {
    final String patientUuid = patient.patientUuid;
    if (patientUuid.isEmpty) return;

    if (newHeight != null && newHeight > 0) {
      final MetricValue? lastHeightMetric = await DatabaseManager()
          .getLatestMetric(patientUuid, 'height');

      if (lastHeightMetric == null || lastHeightMetric.value != newHeight) {
        await DatabaseManager().insertPatientMetric(
          patientUuid,
          newHeight,
          'height',
        );
        setState(() {
          patient.height = newHeight;
        });
      }
    }

    // --- HANDLE WEIGHT FILTER ---
    if (newWeight != null && newWeight > 0) {
      final MetricValue? lastWeightMetric = await DatabaseManager()
          .getLatestMetric(patientUuid, 'weight');
      bool shouldWriteWeight = true;

      if (lastWeightMetric != null) {
        final Duration timeSinceLastLog = DateTime.now().difference(
          lastWeightMetric.recorded,
        );
        if (lastWeightMetric.value == newWeight &&
            timeSinceLastLog.inHours < 23) {
          shouldWriteWeight = false;
        }
      }

      if (shouldWriteWeight) {
        await DatabaseManager().insertPatientMetric(
          patientUuid,
          newWeight,
          'weight',
        );
        setState(() {
          patient.weight = newWeight;
        });
      }
    }
  }
}
