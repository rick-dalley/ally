import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ally/classes/blood_type.dart';
import 'package:ally/classes/metric_value.dart';
import 'package:ally/widgets/avatar_picker.dart';
import 'package:ally/widgets/blood_type_selector.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import 'package:carbon_ui/widgets/carbon_style_two_xl_button.dart';
import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/emergency_lock_screen.dart';
import 'package:carbon_ui/interfaces/flyable.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../classes/patient_pain.dart';
import '../classes/patient_sentiment.dart';
import '../widgets/body_metrics_entry_widget.dart';
import 'body_screen.dart';
import 'wearable_settings_screen.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';
import '../widgets/trophy_case.dart';

class UserScreen extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Patient user;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback? onMedsTap;
  final Function(Patient) onMemberUpdate;
  final VoidCallback? onAddFamilyMember;

  const UserScreen({
    super.key,
    required this.user,
    this.onAssessmentsTap,
    this.onMedsTap,
    required this.onMemberUpdate(Patient patient),
    this.onAddFamilyMember,
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

  void _onAvatarPicked(Uint8List? bytes) {
    final Patient patient = patientController.patient;
    patient.avatar = bytes;
    DatabaseManager().updatePatientAvatar(patient.patientUuid, bytes);
    setState(() {});
    widget.onMemberUpdate(patient);
  }

  // The one pencil icon for everything UserScreen shows read-only but never let anyone
  // touch: PHN, emergency contact, primary caregiver, pharmacy. Blood Type and BMI
  // already have their own dedicated edit affordances (the tiles above), so those stay
  // out of this sheet rather than being duplicated here.
  Future<void> _showEditDetailsSheet(
    BuildContext context,
    Patient patient,
  ) async {
    final TextEditingController phnController = TextEditingController(
      text: patient.phn,
    );
    final TextEditingController contactNameController = TextEditingController(
      text: patient.contactName,
    );
    final TextEditingController contactPhoneController = TextEditingController(
      text: patient.contactPhone,
    );
    final TextEditingController caregiverNameController = TextEditingController(
      text: patient.familyDoctorName,
    );
    final TextEditingController caregiverPhoneController =
        TextEditingController(text: patient.familyDoctorPhone);
    final TextEditingController pharmacyPhoneController = TextEditingController(
      text: patient.pharmacyPhone,
    );
    final TextEditingController pharmacyFaxController = TextEditingController(
      text: patient.pharmacyFax,
    );
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> save() async {
              try {
                await DatabaseManager().updatePatientDetails(
                  patientUuid: patient.patientUuid,
                  phn: phnController.text.trim(),
                  contactName: contactNameController.text.trim(),
                  contactPhone: contactPhoneController.text.trim(),
                  familyDoctorName: caregiverNameController.text.trim(),
                  familyDoctorPhone: caregiverPhoneController.text.trim(),
                  pharmacyPhone: pharmacyPhoneController.text.trim(),
                  pharmacyFax: pharmacyFaxController.text.trim(),
                );
                patient.phn = phnController.text.trim();
                patient.contactName = contactNameController.text.trim();
                patient.contactPhone = contactPhoneController.text.trim();
                patient.familyDoctorName = caregiverNameController.text.trim();
                patient.familyDoctorPhone = caregiverPhoneController.text
                    .trim();
                patient.pharmacyPhone = pharmacyPhoneController.text.trim();
                patient.pharmacyFax = pharmacyFaxController.text.trim();
                setState(() {});
                widget.onMemberUpdate(patient);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } catch (err) {
                setSheetState(
                  () => error =
                      "Couldn't save — that health card number may already "
                      "be in use.",
                );
              }
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit Details",
                      style: CarbonTheme.carbonHeadingTextStyle,
                    ),
                    const SizedBox(height: 24),
                    CarbonTextInput(
                      label: "Provincial Health #:",
                      controller: phnController,
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "CONTACT:",
                      controller: contactNameController,
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PHONE:",
                      controller: contactPhoneController,
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PRIMARY CAREGIVER:",
                      controller: caregiverNameController,
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PHONE:",
                      controller: caregiverPhoneController,
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "PHARMACY:",
                      controller: pharmacyPhoneController,
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "FAX:",
                      controller: pharmacyFaxController,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: CarbonTheme.dangerTextStyle),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CarbonButton(
                            label: "Cancel",
                            alignment: MainAxisAlignment.center,
                            style: CarbonButtonStyle.secondary,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CarbonButton(
                            label: "Save",
                            alignment: MainAxisAlignment.center,
                            style: CarbonButtonStyle.primary,
                            onPressed: save,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    // Fixed close button up top, patient content scrolls independently below it — the
    // sheet itself now fills the safe area (see showUserScreen in home_screen.dart), so
    // dragging isn't the only way out anymore.
    return Stack(
      children: [
        Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AvatarPicker(
                                onPicked: _onAvatarPicked,
                                rawImage: patient.avatar,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      patient.firstName,
                                      style: CarbonTheme.carbonHeadingTextStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    CarbonCompactButton(
                                      icon: Symbols.edit,
                                      label: "Edit Details",
                                      style: CarbonButtonStyle.ghost,
                                      onTap: () => _showEditDetailsSheet(
                                        context,
                                        patient,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                          Column(
                            mainAxisSize: MainAxisSize
                                .min, // Prevents Column from taking infinite height
                            children: [
                              Row(
                                children: [
                                  // Expanded, not a fixed width: 184 — two
                                  // fixed-width cards plus a Spacer() don't
                                  // reliably fit narrower phone widths (this
                                  // was overflowing on-device). 184 stays as
                                  // the widget's ideal/preferred width but
                                  // gets compressed to fit here instead.
                                  Expanded(
                                    child: CarbonStyle2xlButton(
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
                                  ),
                                  SizedBox(width: CarbonSpacing.medium.width),
                                  Expanded(
                                    child: CarbonStyle2xlButton(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: CarbonTextInput(
                                      label: "HEIGHT",
                                      value: patient.height.toString(),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text("(${patient.heightUoM})"),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
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
                              CarbonTextInput(
                                label: "FAX:",
                                value: patient.pharmacyFax,
                              ),
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
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text("Wearable", style: CarbonTheme.carbonLabelTextStyle),
                          const SizedBox(height: 8),
                          Text(
                            "Pair a wearable, choose which orders buzz it, and set who "
                            "gets notified if the panic button is pressed.",
                            style: CarbonTheme.carbonHelperTextStyle,
                          ),
                          const SizedBox(height: 12),
                          CarbonButton(
                            label: "Wearable Settings",
                            icon: Symbols.watch,
                            style: CarbonButtonStyle.secondary,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WearableSettingsScreen(patient: patient)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Bottom-right FAB rather than a banner button up top — easier to reach
        // one-handed, and keeps the header above from getting cluttered.
        if (widget.onAddFamilyMember != null)
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              key: const Key("FAB_AddFamilyMember"),
              heroTag: "user_screen_add_family_member",
              backgroundColor: carbonColorPrimary04,
              foregroundColor: carbonColorButtonOnPrimary,
              // Close this sheet first — the wizard is pushed on the same
              // Navigator as the home screen underneath it, and popping before
              // acting on a selection is this app's established rule for
              // avoiding stuck sheets (see AddPatientsWheel.onAddMember).
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAddFamilyMember!();
              },
              child: const Icon(Symbols.add, size: 32),
            ),
          ),
      ],
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
