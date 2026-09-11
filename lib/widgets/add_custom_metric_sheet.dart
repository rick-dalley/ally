import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_checkbox.dart';
import '../classes/database_manager.dart';
import '../classes/metric_value.dart';

// Lets a patient track something their physician asked about that isn't in
// the curated catalog — deliberately the same shape every curated metric
// already has (name, unit, optional safe range), not a new kind of object.
// Saving both creates the Metric row and starts tracking it immediately —
// "create a metric... then turn that into a card that can be filled in and
// tracked" was one request, not two separate steps.
class AddCustomMetricSheet extends StatefulWidget {
  final String patientUuid;
  const AddCustomMetricSheet({super.key, required this.patientUuid});

  @override
  State<AddCustomMetricSheet> createState() => _AddCustomMetricSheetState();
}

class _AddCustomMetricSheetState extends State<AddCustomMetricSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _unit = TextEditingController();
  final TextEditingController _lower = TextEditingController();
  final TextEditingController _upper = TextEditingController();
  bool _wholeNumbersOnly = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _unit, _lower, _upper]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "Give it a name first.");
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final int metricId = await DatabaseManager().insertCustomMetric(
      name: name,
      isInteger: _wholeNumbersOnly,
      symbol: _unit.text.trim(),
      safeLower: _num(_lower) ?? 0.0,
      safeUpper: _num(_upper) ?? 0.0,
    );
    Metrics.trackMetric(metricId: metricId, patientUuid: widget.patientUuid);
    if (mounted) Navigator.pop(context, true);
  }

  Widget _field(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CarbonTheme.carbonHelperTextStyle),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: CarbonTheme.carbonFieldTextStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: carbonColorField,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: carbonColorLayer02,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Track something new", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 8),
              Text(
                "For anything your doctor asked you to track that isn't already on the list.",
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              const SizedBox(height: 16),
              Text("NAME", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                style: CarbonTheme.carbonFieldTextStyle,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: carbonColorField,
                  hintText: "e.g. Fluid Intake",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
                ),
              ),
              const SizedBox(height: 12),
              Text("UNIT OF MEASURE (optional)", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _unit,
                style: CarbonTheme.carbonFieldTextStyle,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: carbonColorField,
                  hintText: "e.g. mL, steps, mg",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
                ),
              ),
              const SizedBox(height: 8),
              CarbonCheckboxListTile(
                value: _wholeNumbersOnly,
                onChanged: (val) => setState(() => _wholeNumbersOnly = val ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text("Whole numbers only"),
              ),
              const SizedBox(height: 8),
              Text(
                "SAFE RANGE (optional — leave blank if you don't know)",
                style: CarbonTheme.carbonLabelTextStyle,
              ),
              const SizedBox(height: 6),
              Row(children: [_field("Low", _lower), _field("High", _upper)]),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: CarbonTheme.carbonHelperTextStyle?.copyWith(color: carbonColorSupportError),
                ),
              ],
              const SizedBox(height: 16),
              CarbonCompactButton(
                icon: Symbols.check,
                label: "Start Tracking",
                style: CarbonButtonStyle.primary,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
