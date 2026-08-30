import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

// Records a dosage/frequency change as history (medication_change_log) rather than
// silently overwriting the old value — the reason a titration happened is exactly what
// lets a patient and doctor later judge whether a therapy actually worked.
class ChangeMedicationSheet extends StatefulWidget {
  final Medication medication;
  const ChangeMedicationSheet({super.key, required this.medication});

  @override
  State<ChangeMedicationSheet> createState() => _ChangeMedicationSheetState();
}

class _ChangeMedicationSheetState extends State<ChangeMedicationSheet> {
  late final TextEditingController _doseController;
  late final TextEditingController _freqController;
  final TextEditingController _reasonController = TextEditingController();
  String? _reasonError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(text: widget.medication.dose ?? '');
    _freqController = TextEditingController(text: widget.medication.freq ?? '');
  }

  @override
  void dispose() {
    _doseController.dispose();
    _freqController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonError = "Let the care team know why this changed");
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    await DatabaseManager().recordMedicationChange(
      medicationId: widget.medication.id,
      patientUuid: widget.medication.patientUuid,
      previousDose: widget.medication.dose,
      newDose: _doseController.text.trim(),
      previousFreq: widget.medication.freq,
      newFreq: _freqController.text.trim(),
      reason: reason,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Moves with keyboard
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Change Dosage & Frequency", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 4),
            Text(widget.medication.name.toUpperCase(), style: CarbonTheme.carbonHintTextStyle),
            const SizedBox(height: 24),
            CarbonTextInput(controller: _doseController, label: "Dosage", placeHolderText: "e.g. 50 mg"),
            const SizedBox(height: 8),
            CarbonTextInput(
              controller: _freqController,
              label: "Frequency",
              placeHolderText: "e.g. Twice a day",
            ),
            const SizedBox(height: 8),
            CarbonTextInput(
              controller: _reasonController,
              label: "Reason for this change",
              placeHolderText: "e.g. Doctor increased the dose after a follow-up visit",
              maxLines: 3,
              errorText: _reasonError,
              onChanged: (_) {
                if (_reasonError != null) setState(() => _reasonError = null);
              },
            ),
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: _isSaving ? "Saving..." : "Save Change",
              style: CarbonButtonStyle.primary,
              onTap: _isSaving ? null : _save,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}