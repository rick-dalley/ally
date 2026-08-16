import 'package:flutter/foundation.dart';

import 'database_manager.dart';

// Drives the avatar's "come look" ripple. Same shape as ReminderRegistry (a
// ChangeNotifier singleton HomeScreen listens to, loaded/reloaded on patient
// switch) — but this one also needs to react immediately the moment a trophy is
// won or acknowledged, not just on the next patient switch or 5-minute poll, so
// anything that inserts or acknowledges an achievement calls refresh() right after.
class AchievementBadge extends ChangeNotifier {
  AchievementBadge._internal();
  static final AchievementBadge instance = AchievementBadge._internal();

  String? _patientUuid;
  bool hasUnacknowledged = false;

  Future<void> loadForPatient(String patientUuid) async {
    _patientUuid = patientUuid;
    await refresh();
  }

  Future<void> refresh() async {
    final String? patientUuid = _patientUuid;
    if (patientUuid == null) return;
    hasUnacknowledged = await DatabaseManager().hasUnacknowledgedAchievement(
      patientUuid,
    );
    notifyListeners();
  }
}
