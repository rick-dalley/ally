// A way of raising the alarm from the wearable — a manual panic-button press, or the
// device's own fall/slap detection. Each trigger is its own Alertable (independently
// enabled) rather than one flag, since a patient reasonably might want the manual
// button always on but fall-detection off if it's prone to false positives. All
// enabled triggers notify the same shared contact list (see emergency_target.dart) —
// the target list isn't per-trigger, since "who gets called" doesn't change based on
// how the alarm was raised.
enum AlertTrigger { manual, fall, slap }

extension AlertTriggerLabel on AlertTrigger {
  String get defaultLabel {
    switch (this) {
      case AlertTrigger.manual:
        return "Panic Button";
      case AlertTrigger.fall:
        return "Fall Detected";
      case AlertTrigger.slap:
        return "Slap Detected";
    }
  }
}

abstract class Alertable {
  AlertTrigger get trigger;
  String get label;
  bool get enabled;
}

class WearableAlertConfig implements Alertable {
  @override
  final AlertTrigger trigger;
  @override
  final String label;
  @override
  final bool enabled;

  const WearableAlertConfig({required this.trigger, required this.label, required this.enabled});

  // wearable_settings has always-fixed columns (one per trigger), not a rows-per-trigger
  // table — three known triggers today, not an open-ended list — so this reads all
  // three off one row rather than a query per trigger.
  factory WearableAlertConfig.fromRow(AlertTrigger trigger, Map<String, dynamic> row) {
    final String column = switch (trigger) {
      AlertTrigger.manual => 'alert_manual_enabled',
      AlertTrigger.fall => 'alert_fall_enabled',
      AlertTrigger.slap => 'alert_slap_enabled',
    };
    return WearableAlertConfig(trigger: trigger, label: trigger.defaultLabel, enabled: (row[column] as int? ?? 0) == 1);
  }
}

List<WearableAlertConfig> alertConfigsFromRow(Map<String, dynamic> row) {
  return AlertTrigger.values.map((t) => WearableAlertConfig.fromRow(t, row)).toList();
}
