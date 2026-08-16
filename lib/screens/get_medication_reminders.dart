import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/medication_services.dart';

class GetMedicationReminders extends StatefulWidget {
  final Function(ReminderPreference) onReminderPreferenceChanged;
  const GetMedicationReminders({super.key, required this.onReminderPreferenceChanged});

  @override
  State<GetMedicationReminders> createState() => _GetMedicationRemindersState();
}

const List<int> _leadMinuteOptions = [0, 5, 10, 15, 30];

class _GetMedicationRemindersState extends State<GetMedicationReminders> {
  bool _enabled = false;
  final Set<ReminderChannel> _channels = {};
  int _leadMinutes = 0;
  WearableAlertMode? _wearableMode;

  void _emit() {
    widget.onReminderPreferenceChanged(
      ReminderPreference(enabled: _enabled, channels: _channels, leadMinutes: _leadMinutes, wearableMode: _wearableMode),
    );
  }

  void _toggleChannel(ReminderChannel channel) {
    setState(() {
      if (_channels.contains(channel)) {
        _channels.remove(channel);
        if (channel == ReminderChannel.wearable) _wearableMode = null;
      } else {
        _channels.add(channel);
        if (channel == ReminderChannel.wearable) _wearableMode = WearableAlertMode.both;
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final bool showWearableMode = _enabled && _channels.contains(ReminderChannel.wearable);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reminders", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 8),
            Text("How should we remind you to take this?", style: CarbonTheme.carbonHintTextStyle),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Remind me"),
              subtitle: const Text("Get a nudge each time this dose is due"),
              value: _enabled,
              onChanged: (val) {
                setState(() => _enabled = val);
                _emit();
              },
            ),
            if (_enabled) ...[
              const SizedBox(height: 16),
              Text("How", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderChannel.values.map((channel) {
                  final bool isSelected = _channels.contains(channel);
                  return GestureDetector(
                    onTap: () => _toggleChannel(channel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryColor,
                        border: Border.all(
                          color: isSelected ? carbonColorBorderInteractive : AppTheme.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            channel.icon,
                            size: 18,
                            color: isSelected ? carbonColorInteractive : AppTheme.defaultHintColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            channel.label,
                            style: TextStyle(
                              color: isSelected ? carbonColorInteractive : AppTheme.defaultFontColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (showWearableMode) ...[
                const SizedBox(height: 20),
                Text("On your wearable", style: CarbonTheme.carbonLabelTextStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WearableAlertMode.values.map((mode) {
                    final bool isSelected = _wearableMode == mode;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _wearableMode = mode);
                        _emit();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryColor,
                          border: Border.all(
                            color: isSelected ? carbonColorBorderInteractive : AppTheme.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          mode.label,
                          style: TextStyle(
                            color: isSelected ? carbonColorInteractive : AppTheme.defaultFontColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              Text("How far in advance", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _leadMinuteOptions.map((minutes) {
                  final bool isSelected = _leadMinutes == minutes;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _leadMinutes = minutes);
                      _emit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryColor,
                        border: Border.all(
                          color: isSelected ? carbonColorBorderInteractive : AppTheme.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        minutes == 0 ? "At the time" : "$minutes min before",
                        style: TextStyle(
                          color: isSelected ? carbonColorInteractive : AppTheme.defaultFontColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
