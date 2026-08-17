import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import '../classes/provider.dart';
import '../classes/reminder_registry.dart';
import '../classes/vision_prescription.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_segmented_control.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

// Add/edit in one — widget.existing == null means "not saved yet", matching
// ConfigureConditionDialog/SupplyDetailSheet's dual-purpose shape. A patient fills
// this in right after an eye exam, or when transcribing a paper prescription; it's not
// meant to be revisited often, unlike the medication wizard's data.
class VisionPrescriptionSheet extends StatefulWidget {
  final String patientUuid;
  final VisionPrescription? existing;

  const VisionPrescriptionSheet({super.key, required this.patientUuid, this.existing});

  @override
  State<VisionPrescriptionSheet> createState() => _VisionPrescriptionSheetState();
}

class _VisionPrescriptionSheetState extends State<VisionPrescriptionSheet> {
  late VisionPrescriptionType _type;
  String? _providerUuid;
  DateTime? _issuedDate;
  DateTime? _expiryDate;
  late final TextEditingController _notesController;

  late final TextEditingController _odSphere;
  late final TextEditingController _odCylinder;
  late final TextEditingController _odAxis;
  late final TextEditingController _odAdd;
  late final TextEditingController _osSphere;
  late final TextEditingController _osCylinder;
  late final TextEditingController _osAxis;
  late final TextEditingController _osAdd;
  late final TextEditingController _pd;
  late final TextEditingController _baseCurve;
  late final TextEditingController _diameter;

  late Future<List<_ProviderChoice>> _providersFuture;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final VisionPrescription? e = widget.existing;
    _type = e?.type ?? VisionPrescriptionType.glasses;
    _providerUuid = e?.providerUuid;
    _issuedDate = e?.issuedDate ?? DateTime.now();
    _expiryDate = e?.expiryDate;
    _notesController = TextEditingController(text: e?.notes ?? "");

    _odSphere = TextEditingController(text: e?.odSphere?.toString() ?? "");
    _odCylinder = TextEditingController(text: e?.odCylinder?.toString() ?? "");
    _odAxis = TextEditingController(text: e?.odAxis?.toString() ?? "");
    _odAdd = TextEditingController(text: e?.odAdd?.toString() ?? "");
    _osSphere = TextEditingController(text: e?.osSphere?.toString() ?? "");
    _osCylinder = TextEditingController(text: e?.osCylinder?.toString() ?? "");
    _osAxis = TextEditingController(text: e?.osAxis?.toString() ?? "");
    _osAdd = TextEditingController(text: e?.osAdd?.toString() ?? "");
    _pd = TextEditingController(text: e?.pd?.toString() ?? "");
    _baseCurve = TextEditingController(text: e?.baseCurve?.toString() ?? "");
    _diameter = TextEditingController(text: e?.diameter?.toString() ?? "");

    _providersFuture = DatabaseManager().getProviders(widget.patientUuid).then((rows) {
      return [
        const _ProviderChoice(null, "None on file"),
        ...rows.map((row) => _ProviderChoice(row['provider_uuid'] as String, Provider.fromJson(row).fullName)),
      ];
    });
  }

  @override
  void dispose() {
    for (final c in [
      _notesController,
      _odSphere,
      _odCylinder,
      _odAxis,
      _odAdd,
      _osSphere,
      _osCylinder,
      _osAxis,
      _osAdd,
      _pd,
      _baseCurve,
      _diameter,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());
  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final VisionPrescription record = VisionPrescription(
      id: widget.existing?.id,
      patientUuid: widget.patientUuid,
      providerUuid: _providerUuid,
      type: _type,
      odSphere: _num(_odSphere),
      odCylinder: _num(_odCylinder),
      odAxis: _int(_odAxis),
      odAdd: _num(_odAdd),
      osSphere: _num(_osSphere),
      osCylinder: _num(_osCylinder),
      osAxis: _int(_osAxis),
      osAdd: _num(_osAdd),
      pd: _num(_pd),
      baseCurve: _type == VisionPrescriptionType.contacts ? _num(_baseCurve) : null,
      diameter: _type == VisionPrescriptionType.contacts ? _num(_diameter) : null,
      issuedDate: _issuedDate,
      expiryDate: _expiryDate,
      notes: _notesController.text.trim(),
    );

    try {
      if (record.id == null) {
        await DatabaseManager().insertVisionPrescription(record);
      } else {
        await DatabaseManager().updateVisionPrescription(record);
      }
    } catch (error, stackTrace) {
      debugPrint('[VisionPrescriptionSheet] save failed: $error\n$stackTrace');
      if (mounted) setState(() { _saving = false; _error = 'Save failed: $error'; });
      return;
    }

    // Pop before refreshing reminders — see BookTestSheet._save for why.
    if (mounted) Navigator.pop(context, true);
    try {
      await ReminderRegistry.instance.refresh();
    } catch (error, stackTrace) {
      debugPrint('[VisionPrescriptionSheet] post-pop reminder refresh failed: $error\n$stackTrace');
    }
  }

  Future<void> _delete() async {
    final int? id = widget.existing?.id;
    if (id == null) return;
    await DatabaseManager().deleteVisionPrescription(id);
    if (mounted) Navigator.pop(context, true);
    await ReminderRegistry.instance.refresh();
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged, {DateTime? firstDate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CarbonTheme.carbonLabelTextStyle),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(1970),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: carbonColorField,
              border: Border(bottom: BorderSide(color: carbonColorBorderInteractive, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? _formatDate(value) : "Not set",
                    style: value != null ? CarbonTheme.carbonFieldTextStyle : CarbonTheme.carbonHintTextStyle,
                  ),
                ),
                if (value != null)
                  InkWell(onTap: () => onChanged(null), child: const Icon(Symbols.close, size: 18, color: carbonColorIconSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CarbonTheme.carbonHelperTextStyle),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: CarbonTheme.carbonFieldTextStyle,
              decoration: const InputDecoration(
                filled: true,
                fillColor: carbonColorField,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eyeRow(String label, TextEditingController sphere, TextEditingController cylinder, TextEditingController axis, TextEditingController add) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CarbonTheme.carbonLabelTextStyle),
        const SizedBox(height: 6),
        Row(children: [_numberField("Sphere", sphere), _numberField("Cylinder", cylinder)]),
        Row(children: [_numberField("Axis", axis), _numberField("Add", add)]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.existing?.id == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isNew ? "Add a Vision Prescription" : "Edit Vision Prescription", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 20),
            Text("TYPE", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 6),
            CarbonSegmentedControl<VisionPrescriptionType>(
              options: VisionPrescriptionType.values,
              value: _type,
              labelBuilder: (t) => t.label,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
            _eyeRow("Right Eye (OD)", _odSphere, _odCylinder, _odAxis, _odAdd),
            const SizedBox(height: 8),
            _eyeRow("Left Eye (OS)", _osSphere, _osCylinder, _osAxis, _osAdd),
            const SizedBox(height: 8),
            Row(
              children: [
                _numberField("PD", _pd),
                if (_type == VisionPrescriptionType.contacts) ...[
                  _numberField("Base Curve", _baseCurve),
                  _numberField("Diameter", _diameter),
                ],
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<_ProviderChoice>>(
              future: _providersFuture,
              builder: (context, snapshot) {
                final choices = snapshot.data ?? const [];
                if (choices.isEmpty) return const SizedBox.shrink();
                final _ProviderChoice current = choices.firstWhere(
                  (c) => c.providerUuid == _providerUuid,
                  orElse: () => choices.first,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CarbonDropdown(
                    label: "Prescribed By",
                    value: current,
                    items: choices,
                    onChanged: (Listable val) => setState(() => _providerUuid = (val as _ProviderChoice).providerUuid),
                  ),
                );
              },
            ),
            _dateField("Issued", _issuedDate, (d) => setState(() => _issuedDate = d)),
            const SizedBox(height: 12),
            _dateField("Expires", _expiryDate, (d) => setState(() => _expiryDate = d), firstDate: _issuedDate),
            const SizedBox(height: 12),
            CarbonTextInput(label: "Notes", controller: _notesController, maxLines: 2, onChanged: (_) {}),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: CarbonTheme.dangerTextStyle),
            ],
            const SizedBox(height: 12),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? () {} : _save,
            ),
            if (!isNew) ...[
              const SizedBox(height: 8),
              CarbonCompactButton(icon: Symbols.close, label: "Remove", style: CarbonButtonStyle.ghost, onTap: _delete),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProviderChoice implements Listable {
  final String? providerUuid;
  final String name;
  const _ProviderChoice(this.providerUuid, this.name);

  @override
  String get label => name;

  @override
  String get description => '';

  @override
  bool operator ==(Object other) => other is _ProviderChoice && other.providerUuid == providerUuid;

  @override
  int get hashCode => providerUuid.hashCode;
}
