import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/metric_value.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_segmented_control.dart';

// A personal goal, not a clinical boundary — no doctor-authority framing here, unlike
// MetricThresholdSheet. Always a single point (direction says which side of it counts
// as "on track"), never a range.
class MetricTargetSheet extends StatefulWidget {
  final String patientUuid;
  final Metric metric;
  final MetricTarget? existing;

  const MetricTargetSheet({super.key, required this.patientUuid, required this.metric, this.existing});

  @override
  State<MetricTargetSheet> createState() => _MetricTargetSheetState();
}

class _MetricTargetSheetState extends State<MetricTargetSheet> {
  late final TextEditingController _value;
  late TargetDirection _direction;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(text: widget.existing?.targetValue.toString() ?? "");
    _direction = widget.existing?.direction ?? TargetDirection.atLeast;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final double? parsed = double.tryParse(_value.text.trim());
    if (parsed == null) return;
    setState(() => _saving = true);
    await DatabaseManager().setPatientMetricTarget(
      patientUuid: widget.patientUuid,
      metricId: widget.metric.id,
      targetValue: parsed,
      direction: _direction,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _clear() async {
    await DatabaseManager().clearPatientMetricTarget(widget.patientUuid, widget.metric.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.existing == null;
    return Dialog(
      backgroundColor: carbonColorLayer02,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Target for ${widget.metric.name}", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 16),
            Text("DIRECTION", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 6),
            CarbonSegmentedControl<TargetDirection>(
              options: TargetDirection.values,
              value: _direction,
              labelBuilder: (d) => d.label,
              onChanged: (d) => setState(() => _direction = d),
            ),
            const SizedBox(height: 16),
            Text("VALUE", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: CarbonTheme.carbonFieldTextStyle,
              decoration: const InputDecoration(
                filled: true,
                fillColor: carbonColorField,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
              ),
            ),
            const SizedBox(height: 16),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? () {} : _save,
            ),
            if (!isNew) ...[
              const SizedBox(height: 8),
              CarbonCompactButton(icon: Symbols.close, label: "Remove Target", style: CarbonButtonStyle.ghost, onTap: _clear),
            ],
          ],
        ),
      ),
    );
  }
}
