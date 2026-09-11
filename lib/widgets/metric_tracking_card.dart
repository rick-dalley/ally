import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ally/classes/achievement_badge.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:ally/classes/database_manager.dart';
import 'package:ally/classes/reminder_registry.dart';
import 'package:carbon_ui/widgets/carbon_checkbox.dart';
import 'package:carbon_ui/widgets/carbon_toggle.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import 'package:carbon_ui/widgets/carbon_style_number_edit.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';
import 'package:carbon_ui/widgets/carbon_segmented_control.dart';
import 'package:ally/widgets/high_low_close_capsule.dart';
import 'package:ally/widgets/metric_reminder_sheet.dart';
import 'package:ally/widgets/metric_scatter_chart.dart';
import 'package:ally/widgets/metric_source_picker_sheet.dart';
import 'package:ally/widgets/metric_target_sheet.dart';
import 'package:ally/widgets/metric_threshold_sheet.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/metric_source.dart';
import '../classes/metric_value.dart';

// The header capsule zooms into one of these on tap. Colors reuse the same semantics
// established for the scatter chart's dashed reference lines and DualBoundCapsule —
// red for Safe, amber for Healthy, green for Target — so the same color always means
// the same thing everywhere a metric shows bounds.
enum _CapsuleTier { safe, healthy, target }

extension _CapsuleTierDisplay on _CapsuleTier {
  String get label {
    switch (this) {
      case _CapsuleTier.safe:
        return "Safe";
      case _CapsuleTier.healthy:
        return "Healthy";
      case _CapsuleTier.target:
        return "Target";
    }
  }

  Color get color {
    switch (this) {
      case _CapsuleTier.safe:
        return carbonColorSupportError;
      case _CapsuleTier.healthy:
        return carbonColorSupportWarning;
      case _CapsuleTier.target:
        return carbonColorSupportSuccess;
    }
  }
}

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
  final MetricSourceSelection? source;
  final MetricReminderPreference reminderPreference;
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
    this.source,
    this.reminderPreference = const MetricReminderPreference(),
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
  // Purely a display default until the patient actually picks something — nothing is
  // written to the DB until _pickSource/_pickSourceDetail runs.
  late MetricSourceType selectedSource =
      widget.source?.source ?? MetricSourceType.observation;
  late String? selectedSourceDetail = widget.source?.sourceDetail;
  bool expanded = false;
  bool showInfoView = false; // true if opened via '?' button
  // Only used by tracked cards — transient, closes again once the reading is
  // saved/canceled (see _buildReadingInputRow). Schedule has no equivalent —
  // its pencil opens the reminder sheet directly, nothing to expand in-card.
  bool _readingExpanded = false;
  // Which tier the header capsule is currently zoomed into — cycles Safe -> Healthy ->
  // Target on tap. Index rather than the enum itself so it survives a tier disappearing
  // (e.g. target removed) without needing to be reset; it just wraps against whatever
  // tiers are available on the next build.
  int _capsuleTierIndex = 0;
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
  double? get healthyLow =>
      widget.threshold?.healthyLow ?? widget.metric.healthyLowerValue;
  double? get healthyHigh =>
      widget.threshold?.healthyHigh ?? widget.metric.healthyUpperValue;
  List<Map<String, dynamic>> get history => widget.historicalValues ?? [];
  MetricRange get range => widget.range ?? MetricRange(id: widget.metric.id);
  // MetricRange.latest defaults to 0.0, not null, so it can't tell "never
  // recorded" from "recorded a 0" — measured (a timestamp) is only ever set
  // by getRangesFor when a real reading exists, so it's the reliable signal.
  bool get hasExistingReading => range.measured != null;

  // Which tiers the header capsule can zoom into — only ones the patient actually has
  // data for. Safe is always available (it falls back to 0.0/0.0 like the rest of the
  // card does), Healthy and Target only appear once they're actually set.
  List<_CapsuleTier> get _availableCapsuleTiers {
    final List<_CapsuleTier> tiers = [_CapsuleTier.safe];
    if (healthyLow != null || healthyHigh != null) {
      tiers.add(_CapsuleTier.healthy);
    }
    if (widget.target != null) tiers.add(_CapsuleTier.target);
    return tiers;
  }

  // A tap-to-zoom band around the target, since a target is a single value rather than
  // a range. Reuses whatever real range is already on hand so the "zoom" actually means
  // something, rather than inventing an arbitrary window.
  double get _targetBandHalfWidth {
    final double? hl = healthyLow, hh = healthyHigh;
    if (hl != null && hh != null && hh > hl) return (hh - hl) / 2;
    if (usl > lsl) return (usl - lsl) / 2;
    return (widget.target?.targetValue ?? 0).abs() * 0.1 + 1;
  }

  @override
  void initState() {
    super.initState();
    isNewValueEnabled = false;

    config = widget.savedConfig ?? {};
  }

  @override
  void didUpdateWidget(covariant MetricExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `tracked`/`onDashboard` are local mutable copies (the card's own
    // checkbox/toggle write to them directly) so they don't just re-read
    // widget.tracked on every build — but that means a change driven from
    // outside this card (a paired metric like BP systolic/diastolic being
    // auto-tracked alongside the one the patient actually tapped, see
    // MetricsDashboardScreenState.handleTrackingChanged) would otherwise
    // never reach this card's own checkbox/sections at all.
    if (oldWidget.tracked != widget.tracked) tracked = widget.tracked;
    if (oldWidget.onDashboard != widget.onDashboard) onDashboard = widget.onDashboard;
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

  Future<void> _stopTrackingTarget() async {
    await DatabaseManager().clearPatientMetricTarget(
      widget.patientUuid,
      widget.metric.id,
    );
    widget.onDataChanged?.call();
  }

  // Signed so "still to go" reads naturally regardless of which side of the target
  // counts as on-track — positive always means "not there yet", never negative once met.
  double _distanceValue(MetricTarget target, double current) {
    switch (target.direction) {
      case TargetDirection.atLeast:
        return target.targetValue - current;
      case TargetDirection.atMost:
        return current - target.targetValue;
      case TargetDirection.exact:
        return (target.targetValue - current).abs();
    }
  }

  String _distanceToTarget(MetricTarget target) {
    final double? current = range.latest;
    if (current == null) return "No readings yet";
    final double distance = _distanceValue(target, current);
    if (distance <= 0) return "Target met";
    return distance.toStringAsFixed(1);
  }

  Future<void> _editReminder() async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) => MetricReminderSheet(
        patientUuid: widget.patientUuid,
        metric: widget.metric,
        existing: widget.reminderPreference,
      ),
    );
    if (saved == true) {
      widget.onDataChanged?.call();
      // Without this, a just-enabled reminder wouldn't show up until the registry's
      // next 5-minute poll — same reasoning as every other reminder-creating flow.
      await ReminderRegistry.instance.refresh();
    }
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
    await _checkTargetAchievement(value);
    // The parent owns range/history for this metric, same reasoning as threshold/target
    // edits above — this card doesn't try to update its own copy, it asks the parent to
    // reload and hand back fresh widget.range/widget.historicalValues.
    widget.onDataChanged?.call();
  }

  // Awarded once per target, not once per qualifying reading — hasAchievement guards
  // against a second (or hundredth) reading that still meets an already-won target
  // minting another trophy. Reaching a *new* target after editing it can win again,
  // since it's a genuinely different name ("Reached target for X" is the same string
  // regardless of the target's value, so changing the target value doesn't itself
  // re-open it — only removing and setting a fresh target does, same as the rest of
  // this card's "target" concept treats an edit vs a new target).
  Future<void> _checkTargetAchievement(double value) async {
    final MetricTarget? target = widget.target;
    if (target == null) return;
    if (_distanceValue(target, value) > 0) return;

    final String name = "Reached target for ${widget.metric.name}";
    if (await DatabaseManager().hasAchievement(
      patientUuid: widget.patientUuid,
      name: name,
    )) {
      return;
    }

    await DatabaseManager().insertAchievement(
      patientUuid: widget.patientUuid,
      name: name,
      reason:
          "${target.direction.label} ${target.targetValue} — reached with a reading of $value",
      icon: "🏆",
    );
    // Without this the avatar ripple wouldn't appear until the next patient switch —
    // this is the moment that's actually supposed to make them curious to go look.
    await AchievementBadge.instance.refresh();
  }

  void _persistSource() {
    Metrics.setSource(
      metricId: widget.metric.id,
      patientUuid: widget.patientUuid,
      source: selectedSource,
      sourceDetail: selectedSourceDetail,
    );
    widget.onDataChanged?.call();
  }

  void _changeSourceType(MetricSourceType type) {
    setState(() {
      selectedSource = type;
      selectedSourceDetail = null;
    });
    // Deliberately doesn't persist yet — flipping the segment alone ("Device") without
    // saying which device isn't a complete answer worth recording; only picking the
    // detail below actually writes anything.
  }

  Future<void> _pickSourceDetail() async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MetricSourcePickerSheet(
        sourceType: selectedSource,
        metricCategory: widget.metric.category,
        patientUuid: widget.patientUuid,
        metricId: widget.metric.id,
      ),
    );
    if (picked == null) return;
    setState(() => selectedSourceDetail = picked);
    _persistSource();
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
          color: carbonColorIconPrimary,
        );
    final Color tileColor = CarbonTheme.getTileColor(
      CarbonTileStyle.expandable,
    );
    // Tracked state is signalled by a left accent bar (same language as
    // InteractionsChip's notice) rather than icon opacity — opacity alone
    // read as "pale pink" and washed out at a glance while scrolling, and
    // overloaded the icon's color with two jobs (metric identity + tracked
    // state) at once.
    final Border tileBorder = tracked
        ? Border(
            top: const BorderSide(color: carbonColorBorderSubtle03, width: 1),
            right: const BorderSide(color: carbonColorBorderSubtle03, width: 1),
            bottom: const BorderSide(color: carbonColorBorderSubtle03, width: 1),
            left: BorderSide(color: carbonColorPrimary04, width: 3),
          )
        : const Border.fromBorderSide(
            BorderSide(color: carbonColorBorderSubtle03, width: 1),
          );

    return Card(
      color: tileColor,
      shape: ContinuousRectangleBorder(),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(border: tileBorder),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Row: Icon on left, Title, Checkbox on far right
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(metricIcon.iconData, color: metricIcon.color, size: 24),
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
                        child: tracked
                            // Once tracked, the card is busy enough (reading,
                            // schedule) that the description just adds clutter —
                            // it moves behind an (i) next to the title instead of
                            // disappearing outright, see _showMetricInfo.
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(title, style: CarbonTheme.carbonTextStyle),
                                  ),
                                  InkWell(
                                    onTap: _showMetricInfo,
                                    child: const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Icon(Symbols.info, size: 16, color: carbonColorIconSecondary),
                                    ),
                                  ),
                                ],
                              )
                            : Text(title, style: CarbonTheme.carbonTextStyle),
                      ),
                      SizedBox(height: 8.0),
                      if (!tracked)
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
                  Builder(
                    builder: (context) {
                      final List<_CapsuleTier> tiers = _availableCapsuleTiers;
                      final _CapsuleTier activeTier =
                          tiers[_capsuleTierIndex % tiers.length];
                      final double clinicalMin;
                      final double clinicalMax;
                      switch (activeTier) {
                        case _CapsuleTier.safe:
                          clinicalMin = lsl;
                          clinicalMax = usl;
                          break;
                        case _CapsuleTier.healthy:
                          clinicalMin = healthyLow ?? lsl;
                          clinicalMax = healthyHigh ?? usl;
                          break;
                        case _CapsuleTier.target:
                          final double target = widget.target!.targetValue;
                          final double band = _targetBandHalfWidth;
                          clinicalMin = target - band;
                          clinicalMax = target + band;
                          break;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 0.0,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: tiers.length > 1
                              ? () => setState(() => _capsuleTierIndex++)
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HighLowCloseCapsule(
                                current: range.latest ?? 0.0,
                                historicalMin: range.minimum ?? 0.0,
                                historicalMax: range.maximum ?? 0.0,
                                clinicalMin: clinicalMin,
                                clinicalMax: clinicalMax,
                                height: 60,
                                color: carbonColorPrimary04,
                              ),
                              if (tiers.length > 1) ...[
                                const SizedBox(height: 2),
                                Text(
                                  activeTier.label,
                                  style: CarbonTheme.carbonHelperTextStyle
                                      ?.copyWith(color: activeTier.color),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if (!tracked)
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: CarbonCheckbox(
                      value: tracked,
                      onChanged: (val) {
                        final bool nowTracked = val ?? false;
                        setState(() {
                          tracked = nowTracked;
                          if (tracked) {
                            expanded = true;
                            showInfoView = false;
                            // Newly tracked — open both sections right away
                            // so the patient can capture the full picture
                            // (a reading, a schedule) in one motion instead
                            // of hunting for two more taps. Reading opens
                            // straight into add mode (no existing reading to
                            // edit yet); Schedule has no in-card expanded
                            // state anymore (see _buildScheduleSection), so
                            // "opened" means launching its sheet directly,
                            // below, once this frame settles.
                            _readingExpanded = true;
                            isNewValueEnabled = true;
                            newValueController.text = '';
                          }
                          widget.onTrackingChanged(tracked);
                        });
                        if (nowTracked) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            newValueControllerFocusNode.requestFocus();
                            _editReminder();
                          });
                        }
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
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Show on Dashboard",
                        style: CarbonTheme.carbonLabelTextStyle,
                      ),
                    ),
                    CarbonToggle(
                      value: onDashboard,
                      onChanged: (val) {
                        setState(() => onDashboard = val);
                        widget.onDashboardChanged?.call(onDashboard);
                      },
                    ),
                  ],
                ),
              ),
            if (tracked) ...[
              _buildReadingSection(),
              _buildScheduleSection(),
            ],
            // Untracked cards keep the original single expand arrow + combined
            // info/tracking-details flow, unchanged — see _buildInfoContent and
            // _buildTrackingDetailsContent.
            if (!tracked) ...[
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
          ],
        ),
      ),
    );
  }

  bool activeButCollapsed() {
    return tracked && !expanded;
  }

  // Replaces the always-visible description once a card is tracked (see the
  // header's info icon) — same content _buildInfoContent shows, but as a
  // simple dismissible dialog rather than something living inside the old
  // combined expand flow, which tracked cards no longer use.
  Future<void> _showMetricInfo() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 12),
              Text(widget.description, style: CarbonTheme.carbonTextStyle),
              if (widget.whyItMatters.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text("Why it matters", style: CarbonTheme.carbonLabelTextStyle),
                const SizedBox(height: 4),
                Text(widget.whyItMatters, style: CarbonTheme.carbonTextStyle),
              ],
              const SizedBox(height: 20),
              CarbonButton(
                icon: Symbols.check,
                label: "Got it",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The reading input row — was always visible on a tracked card; now it's
  // the Reading section's expanded content, right above the chart/ranges.
  // Only ever shown once the Reading section's pencil/+ has already put it in
  // edit mode (see _buildReadingSection) — no separate "Add"/"Edit" button of
  // its own anymore, the header icons are that trigger now.
  Widget _buildReadingInputRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Replaces Spacer safely
      children: [
        Expanded(
          child: CarbonNumberInput(
            label: "Latest Reading",
            decimals: !widget.metric.isInteger,
            controller: newValueController,
            focusNode: newValueControllerFocusNode,
            hint: "Enter a reading",
            enabled: isNewValueEnabled,
            value: hasExistingReading ? range.latest : null,
          ),
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: Align(
            alignment: AlignmentGeometry.centerLeft,
            child: CarbonAcceptButton(
              style: CarbonButtonStyle.primary,
              onAccepted: (accepted) {
                Future.microtask(() {
                  setState(() {
                    isNewValueEnabled = false;
                    // Closes the whole section back to its one-line summary
                    // on either confirm or cancel — the expanded state is a
                    // transient editing mode, not something left open.
                    _readingExpanded = false;
                    if (!accepted) {
                      newValueController.text = hasExistingReading
                          ? range.latest!.toString()
                          : '';
                    }
                  });
                });
                newValueControllerFocusNode.unfocus();
                if (accepted) _saveNewReading();
              },
            ),
          ),
        ),
      ],
    );
  }

  // Formats a reading value the same way the reading input row's decimals
  // flag implies — whole numbers for integer metrics, one decimal otherwise.
  String _formatReading(double value) =>
      value.toStringAsFixed(widget.metric.isInteger ? 0 : 1);

  // Puts the reading input row into edit or add mode and reveals it —
  // shared by both the pencil and + icons in _buildReadingSection, which
  // differ only in whether they seed the field from the current value.
  void _openReadingInput({required bool asEdit}) {
    setState(() {
      _readingExpanded = true;
      isNewValueEnabled = true;
      // Edit starts from what's already recorded (the whole point of editing
      // is correcting that number); Add starts blank — "0" shows only as a
      // placeholder, not a real value the patient has to backspace first.
      newValueController.text = asEdit && hasExistingReading
          ? range.latest!.toString()
          : '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newValueControllerFocusNode.requestFocus();
    });
  }

  Widget _buildReadingSection() {
    final String unit = widget.metric.unitsOfMeasure.isNotEmpty
        ? widget.metric.unitsOfMeasure.first.symbol
        : '';
    final String summary = hasExistingReading
        ? "${_formatReading(range.latest!)}${unit.isEmpty ? '' : ' $unit'}"
        : "No readings yet";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text("Reading: $summary", style: CarbonTheme.carbonTextStyle),
              ),
              // Editing an existing reading only makes sense once one exists.
              if (hasExistingReading)
                IconButton(
                  icon: const Icon(Symbols.edit, size: 18),
                  tooltip: "Edit latest reading",
                  onPressed: () => _openReadingInput(asEdit: true),
                ),
              IconButton(
                icon: const Icon(Symbols.add, size: 18),
                tooltip: "Add a reading",
                onPressed: () => _openReadingInput(asEdit: false),
              ),
            ],
          ),
        ),
        if (_readingExpanded) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadingInputRow(),
                const SizedBox(height: 16),
                _buildRangesAndTargetContent(),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildCaptureSourceContent(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSection() {
    final String summary = widget.reminderPreference.enabled
        ? "${widget.reminderPreference.cadence.description}, ${widget.reminderPreference.reminderTime ?? ''}"
        : "No reminder set";

    // No expand state — the pencil opens the existing reminder-editing
    // sheet directly, same as before, just without the intermediate
    // "Edit reminder" text button.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text("Schedule: $summary", style: CarbonTheme.carbonTextStyle),
          ),
          IconButton(
            icon: const Icon(Symbols.edit, size: 18),
            tooltip: widget.reminderPreference.enabled ? "Edit reminder" : "Remind me to take readings",
            onPressed: _editReminder,
          ),
        ],
      ),
    );
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
        _buildRangesAndTargetContent(),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Text("REMINDER", style: CarbonTheme.carbonLabelTextStyle),
        const SizedBox(height: 4),
        Text(
          widget.reminderPreference.enabled
              ? "${widget.reminderPreference.cadence.description}, ${widget.reminderPreference.reminderTime ?? ''}"
              : "No reminder set",
          style: CarbonTheme.carbonTextStyle,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _editReminder,
            icon: const Icon(Symbols.edit, size: 16),
            label: Text(
              widget.reminderPreference.enabled
                  ? "Edit reminder"
                  : "Remind me to take readings",
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 16),
        _buildCaptureSourceContent(),
      ],
    );
  }

  // Chart + safe/healthy ranges + target — shared by the untracked card's
  // combined expand flow (_buildTrackingDetailsContent, unchanged) and the
  // tracked card's Reading section (_buildReadingSection).
  Widget _buildRangesAndTargetContent() {
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
            safeMin: lsl,
            safeMax: usl,
            healthyMin: healthyLow,
            healthyMax: healthyHigh,
            targetValue: widget.target?.targetValue,
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
                    _rangeLabel(healthyLow, healthyHigh),
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
        if (target == null)
          CarbonCheckboxListTile(
            value: false,
            onChanged: (val) {
              if (val == true) _editTarget();
            },
            title: const Text("Do you wish to set a target?"),
          )
        else ...[
          Text(
            "Target: ${target.targetValue}",
            style: CarbonTheme.carbonTextStyle,
          ),
          const SizedBox(height: 2),
          Text(
            "Distance to target: ${_distanceToTarget(target)}",
            style: CarbonTheme.carbonHelperTextStyle,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                icon: const Icon(Symbols.edit, size: 18),
                onPressed: _editTarget,
                tooltip: "Change target",
              ),
              IconButton(
                icon: const Icon(Symbols.close, size: 18),
                onPressed: _stopTrackingTarget,
                tooltip: "Stop tracking this target",
              ),
            ],
          ),
        ],
      ],
    );
  }

  // "How are these readings captured?" — shared the same way as
  // _buildRangesAndTargetContent above.
  Widget _buildCaptureSourceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "How are these readings captured?",
          style: CarbonTheme.carbonLabelTextStyle,
        ),
        const SizedBox(height: 8),
        CarbonSegmentedControl<MetricSourceType>(
          options: MetricSourceType.values,
          value: selectedSource,
          labelBuilder: (s) => s.label,
          onChanged: _changeSourceType,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _pickSourceDetail,
            icon: const Icon(Symbols.search, size: 16),
            label: Text(
              selectedSourceDetail ??
                  (selectedSource == MetricSourceType.device
                      ? "Which device?"
                      : "How was this observed?"),
            ),
          ),
        ),
      ],
    );
  }
}
