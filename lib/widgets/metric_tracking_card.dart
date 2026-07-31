import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';
import 'package:triage/widgets/carbon_style_number_edit.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';
import 'package:triage/widgets/high_low_close_capsule.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/metric_value.dart';

class MetricExpandableCard extends StatefulWidget {
  final bool tracked;
  final Metric metric;
  final MetricRange? range;
  final String description;
  final String whyItMatters;
  final IconData categoryIcon;
  final bool isInitiallyTracked;
  final Function(bool) onTrackingChanged;
  final List<Map<String, dynamic>>? historicalValues;
  final Map<String, dynamic>? savedConfig;
  const MetricExpandableCard({
    super.key,
    required this.tracked,
    required this.metric,
    required this.description,
    required this.whyItMatters,
    required this.categoryIcon,
    required this.onTrackingChanged,
    this.isInitiallyTracked = false,
    this.historicalValues,
    this.savedConfig,
    this.range,
  });

  @override
  State<MetricExpandableCard> createState() => MetricExpandableCardState();
}

class MetricExpandableCardState extends State<MetricExpandableCard> {
  late bool tracked = widget.tracked;
  bool expanded = false;
  bool showInfoView = false; // true if opened via '?' button
  // Form states for tracking details
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _upperLimitController = TextEditingController();
  final TextEditingController _lowerLimitController = TextEditingController();
  bool showMedicalLimits = false;
  bool showHealthyLimits = false;
  String? linkedResource;
  late List<Map<String, dynamic>> history;
  late Map<String, dynamic> config;
  late String title = widget.metric.name;
  late double usl = widget.metric.safeUpperValue ?? 0.0;
  late double lsl = widget.metric.safeLowerValue ?? 0.0;
  late MetricRange range = widget.range ?? MetricRange(id: widget.metric.id);
  @override
  void initState() {
    super.initState();
    history = widget.historicalValues ?? [];
    config = widget.savedConfig ?? {};
    tracked = widget.isInitiallyTracked;
  }

  @override
  void dispose() {
    _targetController.dispose();
    _upperLimitController.dispose();
    _lowerLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MetricIcon metricIcon =
        metricIcons[widget.metric.name] ??
        MetricIcon(iconData: Symbols.unknown_2, color: CarbonTheme.getButtonColor(CarbonButtonStyle.secondary));
    Color borderColor = tracked
        ? CarbonTheme.getTileBorderColor(CarbonTileStyle.selectable, tracked)
        : carbonColorBorderSubtle03;
    return Card(
      color: carbonColorButtonTertiary,
      shape: ContinuousRectangleBorder(),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(border: Border.all(color: borderColor, width: 1)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Row: Icon on left, Title, Checkbox on far right
            Row(
              children: [
                SizedBox(width: 16.0, height: 16.0),
                Icon(
                  metricIcon.iconData,
                  color: tracked ? metricIcon.color : metricIcon.color.withValues(alpha: 0.4),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: CarbonTheme.carbonTextStyle)),
                if (!tracked)
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: Checkbox(
                      value: tracked,
                      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
                      onChanged: (val) {
                        setState(() {
                          tracked = val ?? false;
                          if (tracked) {
                            expanded = true;
                            showInfoView = false;
                          }
                          widget.onTrackingChanged(tracked);
                        });
                      },
                    ),
                  ),
                if (tracked)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: HighLowCloseCapsule(
                      current: range.latest ?? 0.0,
                      historicalMin: range.minimum ?? 0.0,
                      historicalMax: range.maximum ?? 0.0,
                      clinicalMin: lsl,
                      clinicalMax: usl,
                      height: 60,
                      color: carbonColorPrimary04,
                    ),
                  ),
              ],
            ),

            // Second Line: Description on left, HLC or '?' bubble on right, and the arrow on the far right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(child: Text(widget.description, style: CarbonTheme.carbonTextStyle)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                        if (!expanded) showInfoView = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AnimatedRotation(
                        turns: expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Symbols.arrow_downward, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Body Section (Appears below the second line when expanded)
            if (expanded) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(height: 1, thickness: 1)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: showInfoView ? _buildInfoContent() : _buildTrackingDetailsContent(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool activeButCollapsed() {
    return tracked && !expanded;
  }

  Widget _buildInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        CarbonTextInput(label: 'Why It Matters'),
        const SizedBox(height: 8),
        Text(widget.whyItMatters, style: CarbonTheme.carbonTextStyle),
        const SizedBox(height: 16),
        Text("Doctor Consultation Advice", style: CarbonTheme.carbonTextStyle),
        const SizedBox(height: 8),
        Text(
          "If you believe this metric is clinically relevant to your baseline or personal health journey, please consult your primary physician or specialist before starting active recording.",
          style: CarbonTheme.carbonTextStyle,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  expanded = false;
                  showInfoView = false;
                });
              },
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 12),
            CarbonButton(
              onPressed: () {
                setState(() {
                  tracked = true;
                  showInfoView = false;
                });
              },
              label: 'Track',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: CarbonTheme.getTileColor(CarbonTileStyle.base),
            border: Border.all(color: CarbonTheme.getTileBorderColor(CarbonTileStyle.base, false)),
          ),
          child: Center(
            child: Text(
              "Trend Graph (Empty)\nCurve fit & data points will appear as values are tracked.",
              textAlign: TextAlign.center,
              style: CarbonTheme.carbonHintTextStyle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CarbonNumberInput(controller: _targetController, label: 'Target Value'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CarbonNumberInput(controller: _upperLimitController, label: 'Upper Limit (Alarm)'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CarbonNumberInput(controller: _lowerLimitController, label: 'Lower Limit (Alarm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text("Display Medical Set Limits", style: TextStyle(fontSize: 13)),
          value: showMedicalLimits,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) => setState(() => showMedicalLimits = val ?? false),
        ),
        CheckboxListTile(
          title: const Text("Display Universally Accepted Healthy Limits", style: TextStyle(fontSize: 13)),
          value: showHealthyLimits,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) => setState(() => showHealthyLimits = val ?? false),
        ),
        const SizedBox(height: 16),
        CarbonDropdown<JourneySupports>(
          label: 'Link Journey Support',
          items: JourneySupports.values,
          onChanged: (value) {},
          value: JourneySupports.values.first,
        ),
      ],
    );
  }
}
