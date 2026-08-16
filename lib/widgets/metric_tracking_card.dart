import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/widgets/carbon_checkbox.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';
import 'package:triage/widgets/carbon_style_number_edit.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';
import 'package:triage/widgets/high_low_close_capsule.dart';
import 'package:triage/widgets/metric_scatter_chart.dart';
import 'package:triage/widgets/metric_target_sheet.dart';
import 'package:triage/widgets/metric_threshold_sheet.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/metric_value.dart';

class MetricExpandableCard extends StatefulWidget {
  final String patientUuid;
  final bool tracked;
  final Metric metric;
  final MetricRange? range;
  final MetricThreshold? threshold;
  final MetricTarget? target;
  final String description;
  final String whyItMatters;
  final IconData categoryIcon;
  final Function(bool) onTrackingChanged;
  final bool onDashboard;
  final Function(bool)? onDashboardChanged;
  // Called after the patient saves/removes a threshold or target — the parent owns the
  // source-of-truth maps this card was built from, so it needs to reload and rebuild
  // this card with the fresh data rather than this card tracking it independently.
  final VoidCallback? onDataChanged;
  final List<Map<String, dynamic>>? historicalValues;
  final Map<String, dynamic>? savedConfig;
  const MetricExpandableCard({
    super.key,
    required this.patientUuid,
    required this.tracked,
    required this.metric,
    required this.description,
    required this.whyItMatters,
    required this.categoryIcon,
    required this.onTrackingChanged,
    this.onDashboard = false,
    this.onDashboardChanged,
    this.threshold,
    this.target,
    this.onDataChanged,
    this.historicalValues,
    this.savedConfig,
    this.range,
  });

  @override
  State<MetricExpandableCard> createState() => MetricExpandableCardState();
}

class MetricExpandableCardState extends State<MetricExpandableCard> {
  late bool tracked = widget.tracked;
  late bool onDashboard = widget.onDashboard;
  bool expanded = false;
  bool showInfoView = false; // true if opened via '?' button
  final TextEditingController newValueController = TextEditingController();
  late final FocusNode newValueControllerFocusNode = FocusNode();
  late Map<String, dynamic> config;
  late String title = widget.metric.name;
  late bool isNewValueEnabled = false;

  // Getters, not `late` fields — a `late` field computed from `widget.x` only ever
  // evaluates once (the first time it's read), so it goes stale the moment the parent
  // reloads fresh data and rebuilds this card with the same ValueKey(metric.id) (which
  // keeps this State object alive rather than recreating it). A getter re-reads
  // `widget.x` on every access instead. `history`/`range` hit this exact trap — a saved
  // reading never appeared because both were plain fields snapshotted once in initState.
  double get usl =>
      widget.threshold?.dangerHigh ?? widget.metric.safeUpperValue ?? 0.0;
  double get lsl =>
      widget.threshold?.dangerLow ?? widget.metric.safeLowerValue ?? 0.0;
  List<Map<String, dynamic>> get history => widget.historicalValues ?? [];
  MetricRange get range => widget.range ?? MetricRange(id: widget.metric.id);

  @override
  void initState() {
    super.initState();
    isNewValueEnabled = false;

    config = widget.savedConfig ?? {};
  }

  @override
  void dispose() {
    newValueControllerFocusNode.dispose();
    newValueController.dispose();
    super.dispose();
  }

  Future<void> _editThresholds() async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) => MetricThresholdSheet(
        patientUuid: widget.patientUuid,
        metric: widget.metric,
        existing: widget.threshold,
      ),
    );
    if (saved == true) widget.onDataChanged?.call();
  }

  Future<void> _editTarget() async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) => MetricTargetSheet(
        patientUuid: widget.patientUuid,
        metric: widget.metric,
        existing: widget.target,
      ),
    );
    if (saved == true) widget.onDataChanged?.call();
  }

  Future<void> _saveNewReading() async {
    final double? value = double.tryParse(newValueController.text.trim());
    if (value == null) return;
    await DatabaseManager().insertPatientMetricReading(
      patientUuid: widget.patientUuid,
      metricId: widget.metric.id,
      value: value,
    );
    newValueController.clear();
    // The parent owns range/history for this metric, same reasoning as threshold/target
    // edits above — this card doesn't try to update its own copy, it asks the parent to
    // reload and hand back fresh widget.range/widget.historicalValues.
    widget.onDataChanged?.call();
  }

  String _rangeLabel(double? low, double? high) {
    if (low == null && high == null) return "Not set";
    return "${low?.toStringAsFixed(1) ?? '—'} to ${high?.toStringAsFixed(1) ?? '—'}";
  }

  @override
  Widget build(BuildContext context) {
    MetricIcon metricIcon =
        metricIcons[widget.metric.name] ??
        MetricIcon(
          iconData: Symbols.unknown_2,
          color: carbonColorBorderSubtle03,
        );
    final Color borderColor = CarbonTheme.getTileBorderColor(
      CarbonTileStyle.expandable,
      tracked,
    );
    final Color tileColor = CarbonTheme.getTileColor(
      CarbonTileStyle.expandable,
    );

    return Card(
      color: tileColor,
      shape: ContinuousRectangleBorder(),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Row: Icon on left, Title, Checkbox on far right
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(
                    metricIcon.iconData,
                    color: tracked
                        ? metricIcon.color
                        : metricIcon.color.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 16.0),
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(title, style: CarbonTheme.carbonTextStyle),
                      ),
                      SizedBox(height: 8.0),
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          widget.description,
                          style: CarbonTheme.carbonLabelTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tracked)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0.0,
                    ),
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
                if (!tracked)
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: CarbonCheckbox(
                      value: tracked,
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
              ],
            ),
            // A metric can be actively tracked without cluttering the top summary panel —
            // this is a deliberate subset, not a rename of "tracked", so it only appears
            // once a metric is already being tracked at all.
            if (tracked)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                child: Row(
                  children: [
                    CarbonCheckbox(
                      value: onDashboard,
                      onChanged: (val) {
                        setState(() => onDashboard = val ?? false);
                        widget.onDashboardChanged?.call(onDashboard);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Show on Dashboard",
                      style: CarbonTheme.carbonLabelTextStyle,
                    ),
                  ],
                ),
              ),
            if (tracked)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Replaces Spacer safely
                  children: [
                    Expanded(
                      child: CarbonNumberInput(
                        label: "Latest Reading",
                        decimals: !widget.metric.isInteger,
                        controller: newValueController,
                        focusNode: newValueControllerFocusNode,
                        hint: "Enter a reading",
                        enabled: isNewValueEnabled,
                        value: isNewValueEnabled ? 0.0 : range.latest ?? '0',
                      ),
                    ),
                    SizedBox(width: 16.0),
                    if (!isNewValueEnabled)
                      Expanded(
                        child: Align(
                          alignment: AlignmentGeometry.centerLeft,
                          child: CarbonButton(
                            label: 'Add a Reading',
                            onPressed: () {
                              setState(() {
                                isNewValueEnabled = true;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                newValueControllerFocusNode.requestFocus();
                              });
                            },
                            icon: Symbols.add,
                          ),
                        ),
                      ),
                    if (isNewValueEnabled)
                      Expanded(
                        child: Align(
                          alignment: AlignmentGeometry.centerLeft,
                          child: CarbonAcceptButton(
                            label: 'Keep',
                            style: CarbonButtonStyle.primary,
                            onAccepted: (accepted) {
                              Future.microtask(() {
                                setState(() {
                                  isNewValueEnabled = false;
                                });
                              });
                              newValueControllerFocusNode.unfocus();
                              if (accepted) _saveNewReading();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Second Line: Description on left, HLC or '?' bubble on right, and the arrow on the far right
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                        if (!expanded) showInfoView = false;
                      });
                    },
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: const Icon(Symbols.arrow_downward, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Expanded Body Section (Appears below the second line when expanded)
            if (expanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: showInfoView
                    ? _buildInfoContent()
                    : _buildTrackingDetailsContent(),
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
    final MetricThreshold? threshold = widget.threshold;
    final MetricTarget? target = widget.target;
    final bool hasCustomSafe =
        threshold?.dangerLow != null || threshold?.dangerHigh != null;
    final bool hasCustomHealthy =
        threshold?.healthyLow != null || threshold?.healthyHigh != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (range.count == 0)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: CarbonTheme.getTileColor(CarbonTileStyle.base),
              border: Border.all(color: carbonColorBorderSubtle03),
            ),
            child: Center(
              child: Text(
                "No data yet",
                textAlign: TextAlign.center,
                style: CarbonTheme.carbonTextStyle,
              ),
            ),
          )
        else
          MetricScatterChart(
            historicalValues: history,
            color: carbonColorPrimary04,
          ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SAFE RANGE", style: CarbonTheme.carbonLabelTextStyle),
                  const SizedBox(height: 4),
                  Text(
                    _rangeLabel(lsl, usl),
                    style: CarbonTheme.carbonTextStyle,
                  ),
                  Text(
                    hasCustomSafe
                        ? "From ${threshold?.setBy ?? 'your doctor'}"
                        : "General guideline",
                    style: CarbonTheme.carbonHelperTextStyle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "HEALTHY RANGE",
                    style: CarbonTheme.carbonLabelTextStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rangeLabel(
                      threshold?.healthyLow ?? widget.metric.healthyLowerValue,
                      threshold?.healthyHigh ?? widget.metric.healthyUpperValue,
                    ),
                    style: CarbonTheme.carbonTextStyle,
                  ),
                  Text(
                    hasCustomHealthy
                        ? "From ${threshold?.setBy ?? 'your doctor'}"
                        : "General guideline",
                    style: CarbonTheme.carbonHelperTextStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _editThresholds,
            icon: const Icon(Symbols.edit, size: 16),
            label: Text(
              hasCustomSafe || hasCustomHealthy
                  ? "Edit what your doctor told you"
                  : "Record what your doctor told you",
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Text("TARGET", style: CarbonTheme.carbonLabelTextStyle),
        const SizedBox(height: 4),
        Text(
          target != null
              ? "${target.direction.label} ${target.targetValue}"
              : "No target set",
          style: CarbonTheme.carbonTextStyle,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _editTarget,
            icon: const Icon(Symbols.edit, size: 16),
            label: Text(target != null ? "Edit target" : "Set a target"),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
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
