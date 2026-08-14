import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/screens/get_medication_color.dart';
import 'package:triage/screens/get_medication_dosage.dart';
import 'package:triage/screens/get_medication_frequency.dart';
import 'package:triage/screens/get_medication_name.dart';
import 'package:triage/screens/get_medication_shape.dart';
import 'package:triage/screens/get_medication_type.dart';
import 'package:triage/widgets/carbon_button_compact.dart';

import '../app_theme.dart';
import '../classes/app_colors.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../classes/uuid.dart';

class AddMedicationWizard extends StatefulWidget {
  final String patientUuid;
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;

  const AddMedicationWizard({
    super.key,
    required this.patientUuid,
    required this.nameController,
    required this.dosageController,
    required this.frequencyController,
  });

  @override
  State<AddMedicationWizard> createState() => _AddMedicationWizardState();
}

class _AddMedicationWizardState extends State<AddMedicationWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Generated once, up front, so every add* call below can target this exact row
  // instead of the DB having to guess which medication "named X" was just added.
  final String _medicationId = uuid.v4();

  String? _dosage;
  Frequency? _frequency;
  MedicationTypes? _type;
  TabletShapes? _shape;
  TabletColors? _color;

  static const int _lastStep = 5; // name, type, dosage, frequency, shape, color
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep == _lastStep) {
      _saveMedication();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goBack() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _saveMedication() async {
    // The name field's own screen supports two entry paths (barcode scan and manual
    // typing) but only the scan path ever fed a value back up through a callback.
    // The text controller is the one thing both paths always keep in sync, so it's
    // the actual source of truth here rather than a separately-tracked field.
    final String name = widget.nameController.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    await DatabaseManager().addMedication(medicationId: _medicationId, name: name, patientUuid: widget.patientUuid);

    if (_dosage != null) {
      await DatabaseManager().addDosage(medicationId: _medicationId, dosage: _dosage!);
    }

    if (_frequency != null) {
      await DatabaseManager().addFrequency(medicationId: _medicationId, frequency: _frequency!);
    }

    if (_type != null) {
      await DatabaseManager().addMedicationType(medicationId: _medicationId, type: _type!);
    }

    if (_shape != null) {
      await DatabaseManager().addMedicationShape(medicationId: _medicationId, shape: _shape!);
    }

    if (_color != null) {
      await DatabaseManager().addMedicationColor(medicationId: _medicationId, color: _color!);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastStep = _currentStep == _lastStep;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(CarbonSpacing.wide.width),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: CarbonCompactButton(
                  icon: Symbols.chevron_backward,
                  label: "Back",
                  style: CarbonButtonStyle.secondary,
                  onTap: _goBack,
                ),
              ),
              const SizedBox(width: 4.0),
            ],
            Expanded(
              child: CarbonCompactButton(
                icon: Symbols.cancel,
                label: "Cancel",
                style: CarbonButtonStyle.ghost,
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: CarbonCompactButton(
                icon: isLastStep ? Symbols.trophy : Symbols.navigate_next,
                style: CarbonButtonStyle.primary,
                label: isLastStep ? (_isSaving ? "Saving..." : "Save") : WizardSteps.values[_currentStep + 1].label,
                onTap: _isSaving ? () {} : _goNext,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _StepProgress(currentStep: _currentStep, stepCount: _lastStep + 1),
          const SizedBox(height: 4),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),

              children: [
                GetMedicationName(
                  nameController: widget.nameController,
                  // The name field itself keeps the text controller in sync regardless of
                  // whether the user scanned a barcode or typed manually; _saveMedication
                  // reads that controller directly, so this callback just keeps the wizard
                  // (e.g. the progress bar) in sync while the user is on this step.
                  onAddMedication: (val) => setState(() {}),
                ),
                GetMedicationType(onTypeSelected: (val) => setState(() => _type = val)),
                GetMedicationDosage(
                  controller: widget.dosageController,
                  onAddDosage: (val) => setState(() => _dosage = val),
                ),
                GetMedicationFrequency(
                  controller: widget.frequencyController,
                  onFrequencySelected: (val) => setState(() => _frequency = val),
                ),
                GetMedicationShape(onShapeSelect: (val) => setState(() => _shape = val)),
                GetMedicationColor(onColorSelect: (val) => setState(() => _color = val)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  final int stepCount;
  const _StepProgress({required this.currentStep, required this.stepCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: List.generate(stepCount, (index) {
          final bool isComplete = index <= currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == stepCount - 1 ? 0 : 6),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.mustard[3] : AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
