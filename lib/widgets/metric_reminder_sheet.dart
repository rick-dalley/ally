import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../classes/metric_value.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_checkbox.dart';
import 'package:carbon_ui/widgets/carbon_segmented_control.dart';

// Same shape as the medication wizard's Reminders step (channels, wearable submode),
// swapping "lead time before a dose" for "how often" + "what time" — a metric reading
// is a recurring habit to build, not a single upcoming event to lead ahead of.
class MetricReminderSheet extends StatefulWidget {
  final String patientUuid;
  final Metric metric;
  final MetricReminderPreference existing;

  const MetricReminderSheet({
    super.key,
    required this.patientUuid,
    required this.metric,
    required this.existing,
  });

  @override
  State<MetricReminderSheet> createState() => _MetricReminderSheetState();
}

class _MetricReminderSheetState extends State<MetricReminderSheet> {
  late bool _enabled = widget.existing.enabled;
  late Set<ReminderChannel> _channels = {...widget.existing.channels};
  late WearableAlertMode? _wearableMode = widget.existing.wearableMode;
  late MetricReminderCadence _cadence = widget.existing.cadence;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final String? raw = widget.existing.reminderTime;
    if (raw != null && raw.contains(':')) {
      final parts = raw.split(':');
      final int? hour = int.tryParse(parts[0]);
      final int? minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (hour != null && minute != null)
        _time = TimeOfDay(hour: hour, minute: minute);
    }
    _time ??= const TimeOfDay(hour: 9, minute: 0);
  }

  void _toggleChannel(ReminderChannel channel) {
    setState(() {
      if (_channels.contains(channel)) {
        _channels.remove(channel);
        if (channel == ReminderChannel.wearable) _wearableMode = null;
      } else {
        _channels.add(channel);
        if (channel == ReminderChannel.wearable)
          _wearableMode = WearableAlertMode.both;
      }
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time!,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final String hhmm =
        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
    await DatabaseManager().saveMetricReminderPreference(
      metricId: widget.metric.id,
      patientUuid: widget.patientUuid,
      enabled: _enabled,
      channels: _channels,
      wearableMode: _wearableMode,
      cadence: _cadence.name,
      reminderTime: hhmm,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bool showWearableMode =
        _enabled && _channels.contains(ReminderChannel.wearable);
    return Dialog(
      backgroundColor: carbonColorLayer02,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reminders for ${widget.metric.name}",
              style: CarbonTheme.carbonHeadingTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              "Get a nudge to take a reading",
              style: CarbonTheme.carbonHintTextStyle,
            ),
            const SizedBox(height: 12),
            CarbonCheckboxListTile(
              value: _enabled,
              onChanged: (val) => setState(() => _enabled = val ?? false),
              title: const Text("Remind me"),
            ),
            if (_enabled) ...[
              const SizedBox(height: 16),
              Text("HOW OFTEN", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              CarbonSegmentedControl<MetricReminderCadence>(
                options: MetricReminderCadence.values,
                value: _cadence,
                labelBuilder: (c) => c.label,
                onChanged: (c) => setState(() => _cadence = c),
                fontSize: 11,
              ),
              const SizedBox(height: 4),
              // The abbreviated segment label ("2W") is tight by necessity — this
              // confirms in plain words what was actually picked, updating live as the
              // selection changes rather than only once on save.
              Text(
                _cadence.description,
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              const SizedBox(height: 16),
              Text("WHAT TIME", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              CarbonCompactButton(
                icon: Symbols.schedule,
                label: _time!.format(context),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              Text("HOW", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              ...ReminderChannel.values.map(
                (channel) => CarbonCheckboxListTile(
                  value: _channels.contains(channel),
                  onChanged: (_) => _toggleChannel(channel),
                  title: Text(channel.label),
                ),
              ),
              if (showWearableMode) ...[
                const SizedBox(height: 8),
                Text(
                  "ON YOUR WEARABLE",
                  style: CarbonTheme.carbonLabelTextStyle,
                ),
                const SizedBox(height: 6),
                CarbonSegmentedControl<WearableAlertMode>(
                  options: WearableAlertMode.values,
                  value: _wearableMode ?? WearableAlertMode.both,
                  labelBuilder: (m) => m.label,
                  onChanged: (m) => setState(() => _wearableMode = m),
                ),
              ],
            ],
            const SizedBox(height: 20),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
