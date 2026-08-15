import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient_condition.dart';
import 'carbon_button_compact.dart';
import 'carbon_segmented_control.dart';
import 'carbon_style_textbox.dart';

class ConfigureConditionDialog extends StatefulWidget {
  final PatientCondition patientCondition;

  const ConfigureConditionDialog({super.key, required this.patientCondition});

  @override
  State<ConfigureConditionDialog> createState() => _ConfigureConditionDialogState();
}

class _ConfigureConditionDialogState extends State<ConfigureConditionDialog> {
  late TextEditingController _notesController;
  late TextEditingController _durationValueController;
  late ConditionStatus _status;
  DateTime? _onset;
  DateTime? _statusDate;
  late DurationUnit _durationUnit;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.patientCondition.treatmentNotes);
    _status = widget.patientCondition.status;
    _onset = widget.patientCondition.onset;
    _statusDate = widget.patientCondition.statusDate;
    _durationUnit = widget.patientCondition.durationEstimateUnit ?? DurationUnit.years;
    _durationValueController = TextEditingController(
      text: widget.patientCondition.durationEstimateValue?.toString() ?? "",
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  String _statusDateLabel() {
    return _status == ConditionStatus.inRemission ? "REMISSION DATE" : "RECOVERY DATE";
  }

  String _formatDate(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // Approximate on purpose — this is a patient's recollection of their own history,
  // not a clinical measurement.
  String _formatApproxDuration(Duration duration) {
    final int totalDays = duration.inDays;
    final int years = totalDays ~/ 365;
    final int months = (totalDays % 365) ~/ 30;
    if (years > 0) {
      return months > 0 ? "$years yr${years == 1 ? '' : 's'}, $months mo" : "$years yr${years == 1 ? '' : 's'}";
    }
    if (months > 0) return "$months mo${months == 1 ? '' : 's'}";
    return "$totalDays day${totalDays == 1 ? '' : 's'}";
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required DateTime firstDate,
    required ValueChanged<DateTime?> onChanged,
  }) {
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
              firstDate: firstDate,
              lastDate: DateTime.now(),
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
                  InkWell(
                    onTap: () => onChanged(null),
                    child: const Icon(Symbols.close, size: 18, color: carbonColorIconSecondary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width;
    final double fixedDialogWidth = availableWidth - 64;
    final Duration? computedDuration = _onset != null
        ? (_statusDate ?? DateTime.now()).difference(_onset!)
        : null;

    return Dialog(
      backgroundColor: carbonColorLayer02,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: fixedDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 8, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          widget.patientCondition.name,
                          style: CarbonTheme.carbonHeadingTextStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.close, color: carbonColorIconSecondary),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CURRENT STATUS", style: CarbonTheme.carbonLabelTextStyle),
                    const SizedBox(height: 6),
                    CarbonSegmentedControl<ConditionStatus>(
                      options: ConditionStatus.values,
                      value: _status,
                      labelBuilder: (s) => s.label,
                      onChanged: (newStatus) => setState(() {
                        _status = newStatus;
                        // Only Active implies "no status date" outright — In Remission
                        // and Recovered both leave whatever status date was already set
                        // (including none) alone, since it's optional either way.
                        if (newStatus == ConditionStatus.active) _statusDate = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: "ONSET DATE",
                      value: _onset,
                      firstDate: DateTime(1900),
                      onChanged: (picked) => setState(() => _onset = picked),
                    ),
                    if (_status != ConditionStatus.active) ...[
                      const SizedBox(height: 16),
                      _buildDateField(
                        label: _statusDateLabel(),
                        value: _statusDate,
                        firstDate: _onset ?? DateTime(1900),
                        onChanged: (picked) => setState(() => _statusDate = picked),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Duration is computed whenever onset is known — never editable
                    // alongside it, so it can't drift out of sync with the dates. Only
                    // when onset is unknown does an approximate estimate make sense.
                    if (computedDuration != null) ...[
                      Text("DURATION", style: CarbonTheme.carbonLabelTextStyle),
                      const SizedBox(height: 6),
                      Text(_formatApproxDuration(computedDuration), style: CarbonTheme.carbonFieldTextStyle),
                    ] else ...[
                      Text("DURATION (APPROXIMATE)", style: CarbonTheme.carbonLabelTextStyle),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 72,
                            child: TextField(
                              controller: _durationValueController,
                              keyboardType: TextInputType.number,
                              style: CarbonTheme.carbonFieldTextStyle,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: carbonColorField,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<DurationUnit>(
                              initialValue: _durationUnit,
                              isExpanded: true,
                              items: [
                                for (final unit in DurationUnit.values)
                                  DropdownMenuItem(value: unit, child: Text(unit.label, style: CarbonTheme.carbonFieldTextStyle)),
                              ],
                              onChanged: (newUnit) {
                                if (newUnit != null) setState(() => _durationUnit = newUnit);
                              },
                              icon: const Icon(Symbols.expand_more, color: carbonColorIconSecondary),
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: carbonColorField,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Not sure of exact dates? Record roughly how long instead.",
                        style: CarbonTheme.carbonHelperTextStyle,
                      ),
                    ],
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "Treatment Notes",
                      controller: _notesController,
                      maxLines: 3,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: CarbonCompactButton(
                  icon: Symbols.check,
                  label: "Confirm Changes",
                  style: CarbonButtonStyle.primary,
                  onTap: () async {
                    widget.patientCondition.treatmentNotes = _notesController.text;
                    widget.patientCondition.status = _status;
                    widget.patientCondition.onset = _onset;
                    widget.patientCondition.statusDate = _status == ConditionStatus.active ? null : _statusDate;

                    if (_onset == null) {
                      widget.patientCondition.durationEstimateValue = int.tryParse(_durationValueController.text.trim());
                      widget.patientCondition.durationEstimateUnit = _durationUnit;
                    } else {
                      widget.patientCondition.durationEstimateValue = null;
                      widget.patientCondition.durationEstimateUnit = null;
                    }

                    final navigator = Navigator.of(context);

                    if (widget.patientCondition.id == null) {
                      await DatabaseManager().insertPatientCondition(widget.patientCondition);
                    } else {
                      await DatabaseManager().updatePatientCondition(widget.patientCondition);
                    }

                    if (mounted) {
                      navigator.pop(true);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
