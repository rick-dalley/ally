import 'package:flutter/material.dart';
import 'package:triage/screens/get_medication_dosage.dart';
import 'package:triage/screens/get_medication_frequency.dart';
import 'package:triage/screens/get_medication_name_page.dart';
import 'package:triage/screens/get_medication_shape.dart';
import 'package:triage/screens/get_medication_type.dart';

import '../app_theme.dart';
import '../classes/carbon_style_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../widgets/carbon_style_button.dart';

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

  String? _medName;
  String? _dosage;
  Frequency? _frequency;
  MedicationTypes? _type;
  MedicationShapes? _shape;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep == 4) {
      _saveMedication();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goBack() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _saveMedication() async {
    if (_medName == null) return;

    await DatabaseManager().addMedication(name: _medName!, patientUuid: widget.patientUuid);

    if (_dosage != null) {
      await DatabaseManager().addDosage(name: _medName!, patientUuid: widget.patientUuid, dosage: _dosage!);
    }

    if (_frequency != null) {
      await DatabaseManager().addFrequency(name: _medName!, patientUuid: widget.patientUuid, frequency: _frequency!);
    }

    if (_type != null) {
      await DatabaseManager().addMedicationType(name: _medName!, patientUuid: widget.patientUuid, type: _type!);
    }

    if (_shape != null) {
      await DatabaseManager().addMedicationShape(name: _medName!, patientUuid: widget.patientUuid, shape: _shape!);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(CarbonSpacing.wide.width),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: CarbonButton(label: "BACK", isSecondary: true, onPressed: _goBack),
              ),
            SizedBox(width: CarbonSpacing.medium.width),
            Expanded(
              child: CarbonButton(label: _currentStep == 4 ? "FINISH" : "NEXT", onPressed: _goNext),
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentStep = idx),

        children: [
          GetMedicationName(
            nameController: widget.nameController,
            onAddMedication: (val) => setState(() => _medName = val),
          ),
          GetMedicationType(onTypeSelected: (val) => setState(() => _type = val)),
          GetMedicationDosage(controller: widget.dosageController, onAddDosage: (val) => setState(() => _dosage = val)),
          GetMedicationFrequency(
            controller: widget.frequencyController,
            onAddFrequency: (val) => setState(() => _frequency = val),
          ),
          GetMedicationShape(onShapeSelect: (val) => setState(() => _shape = val)),
        ],
      ),
    );
  }
}
