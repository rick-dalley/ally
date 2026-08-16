import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/metric_value.dart';
import 'carbon_button_compact.dart';

// Records what a doctor actually told the patient — this app is patient-facing, not
// something a doctor logs into directly, so there's no "doctor authenticates and sets
// this" flow here, only "patient transcribes what they were told." Same trust model as
// recording a diagnosed condition or a vision prescription elsewhere in this app: the
// app never invents these numbers, it only records what a real visit produced. Every
// field is optional — leaving one blank means "use the general population guideline"
// (Metric.safeUpperValue/healthyUpperValue etc.), not zero.
class MetricThresholdSheet extends StatefulWidget {
  final String patientUuid;
  final Metric metric;
  final MetricThreshold? existing;

  const MetricThresholdSheet({super.key, required this.patientUuid, required this.metric, this.existing});

  @override
  State<MetricThresholdSheet> createState() => _MetricThresholdSheetState();
}

class _MetricThresholdSheetState extends State<MetricThresholdSheet> {
  late final TextEditingController _dangerLow;
  late final TextEditingController _dangerHigh;
  late final TextEditingController _healthyLow;
  late final TextEditingController _healthyHigh;
  late final TextEditingController _setBy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dangerLow = TextEditingController(text: e?.dangerLow?.toString() ?? "");
    _dangerHigh = TextEditingController(text: e?.dangerHigh?.toString() ?? "");
    _healthyLow = TextEditingController(text: e?.healthyLow?.toString() ?? "");
    _healthyHigh = TextEditingController(text: e?.healthyHigh?.toString() ?? "");
    _setBy = TextEditingController(text: e?.setBy ?? "");
  }

  @override
  void dispose() {
    for (final c in [_dangerLow, _dangerHigh, _healthyLow, _healthyHigh, _setBy]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());

  Future<void> _save() async {
    setState(() => _saving = true);
    await DatabaseManager().setPatientMetricThreshold(
      patientUuid: widget.patientUuid,
      metricId: widget.metric.id,
      dangerLow: _num(_dangerLow),
      dangerHigh: _num(_dangerHigh),
      healthyLow: _num(_healthyLow),
      healthyHigh: _num(_healthyHigh),
      setBy: _setBy.text.trim().isEmpty ? null : _setBy.text.trim(),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Widget _field(String label, TextEditingController controller) {
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
              Text("What did your doctor say?", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 8),
              Text(
                "Leave anything blank to use the general guideline for ${widget.metric.name} instead.",
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              const SizedBox(height: 16),
              Text("SAFE RANGE", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              Row(children: [_field("Low", _dangerLow), _field("High", _dangerHigh)]),
              const SizedBox(height: 8),
              Text("HEALTHY RANGE", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              Row(children: [_field("Low", _healthyLow), _field("High", _healthyHigh)]),
              const SizedBox(height: 8),
              Text("Told to you by (optional)", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _setBy,
                style: CarbonTheme.carbonFieldTextStyle,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: carbonColorField,
                  hintText: "e.g. Dr. Alvarez",
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
            ],
          ),
        ),
      ),
    );
  }
}
