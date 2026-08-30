import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import '../classes/patient_supply.dart';
import '../classes/reminder_registry.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import 'package:carbon_ui/widgets/carbon_style_number_edit.dart';

// Step two of adding a tracked supply (after SupplyCatalogPickerSheet), and also the
// editor for an already-tracked one — same dual purpose as ConfigureConditionDialog:
// widget.supply.id == null means "not saved yet", not "read-only".
class SupplyDetailSheet extends StatefulWidget {
  final String patientUuid;
  final PatientSupply supply;

  const SupplyDetailSheet({super.key, required this.patientUuid, required this.supply});

  @override
  State<SupplyDetailSheet> createState() => _SupplyDetailSheetState();
}

class _SupplyDetailSheetState extends State<SupplyDetailSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;
  late Future<List<_MedicationChoice>> _medicationChoicesFuture;
  String? _linkedMedicationId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.supply.quantityOnHand.toString());
    _thresholdController = TextEditingController(text: widget.supply.reorderThreshold.toString());
    _linkedMedicationId = widget.supply.linkedMedicationId;
    _medicationChoicesFuture = DatabaseManager().getMedicationsForPatient(widget.patientUuid).then((rows) {
      return [
        const _MedicationChoice(null, "None"),
        ...rows.map((row) => _MedicationChoice(row['id'] as String, row['name'] as String)),
      ];
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final PatientSupply record = PatientSupply(
      id: widget.supply.id,
      name: widget.supply.name,
      category: widget.supply.category,
      quantityOnHand: int.tryParse(_quantityController.text) ?? widget.supply.quantityOnHand,
      reorderThreshold: int.tryParse(_thresholdController.text) ?? widget.supply.reorderThreshold,
      linkedMedicationId: _linkedMedicationId,
    );

    try {
      if (record.id == null) {
        await DatabaseManager().insertPatientSupply(widget.patientUuid, record);
      } else {
        await DatabaseManager().updatePatientSupply(record);
      }
    } catch (error, stackTrace) {
      debugPrint('[SupplyDetailSheet] save failed: $error\n$stackTrace');
      if (mounted) setState(() { _saving = false; _error = 'Save failed: $error'; });
      return;
    }

    // Pop before refreshing reminders — see BookTestSheet._save for why.
    if (mounted) Navigator.pop(context, true);
    try {
      await ReminderRegistry.instance.refresh();
    } catch (error, stackTrace) {
      debugPrint('[SupplyDetailSheet] post-pop reminder refresh failed: $error\n$stackTrace');
    }
  }

  Future<void> _delete() async {
    final int? id = widget.supply.id;
    if (id == null) return;
    await DatabaseManager().deletePatientSupply(id);
    if (mounted) Navigator.pop(context, true);
    await ReminderRegistry.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.supply.id == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.supply.icon, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.supply.name, style: CarbonTheme.carbonHeadingTextStyle)),
              ],
            ),
            const SizedBox(height: 20),
            CarbonNumberInput(
              label: isNew ? "Starting Quantity" : "Quantity on Hand",
              controller: _quantityController,
            ),
            const SizedBox(height: 8),
            CarbonNumberInput(
              label: "Reorder When At or Below",
              controller: _thresholdController,
              hint: "You'll get a reminder once quantity drops to this number.",
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<_MedicationChoice>>(
              future: _medicationChoicesFuture,
              builder: (context, snapshot) {
                final choices = snapshot.data ?? const [];
                if (choices.length <= 1) return const SizedBox.shrink(); // only "None" — nothing to link
                final _MedicationChoice current = choices.firstWhere(
                  (c) => c.id == _linkedMedicationId,
                  orElse: () => choices.first,
                );
                return CarbonDropdown(
                  label: "Link to a Medication (optional)",
                  helperText: "Logging that medication as taken will count down this supply automatically.",
                  value: current,
                  items: choices,
                  onChanged: (Listable val) => setState(() => _linkedMedicationId = (val as _MedicationChoice).id),
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: CarbonTheme.dangerTextStyle),
            ],
            const SizedBox(height: 12),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? null : _save,
            ),
            if (!isNew) ...[
              const SizedBox(height: 8),
              CarbonCompactButton(
                icon: Symbols.close,
                label: "Remove",
                style: CarbonButtonStyle.ghost,
                onTap: _delete,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MedicationChoice implements Listable {
  final String? id;
  final String name;
  const _MedicationChoice(this.id, this.name);

  @override
  String get label => name;

  @override
  String get description => '';

  @override
  bool operator ==(Object other) => other is _MedicationChoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
