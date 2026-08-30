import 'dart:async';

import 'package:flutter/foundation.dart';

import 'body_markers.dart';
import 'database_manager.dart';
import 'frequency_codes.dart';
import 'medication_services.dart';
import 'metric_value.dart';
import 'remindable.dart';
import 'sickness_episode.dart';
import 'vision_prescription.dart';

// Loads every Remindable for the currently-viewed patient and keeps them refreshed
// while the app is running. This is Tier 1 only — it can surface reminders in-app
// (the reminder sheet, an in-app banner) while the app is open or backgrounded-but-
// alive. It cannot fire a chime/vibration/notification while the app is fully closed;
// that needs real OS-level scheduled notifications (flutter_local_notifications +
// platform setup), which is deliberately out of scope for this pass.
class ReminderRegistry extends ChangeNotifier {
  ReminderRegistry._internal();
  static final ReminderRegistry instance = ReminderRegistry._internal();

  static const Duration _pollInterval = Duration(minutes: 5);

  // A "bump" on a medication has nowhere to persist to — its next-reminder time is
  // re-derived fresh from the frequency schedule every refresh, there's no "snoozed
  // until" column. Tracked here in memory instead, keyed by medication id, and cleared
  // once the snoozed time has passed.
  final Map<String, DateTime> _medicationSnoozes = {};

  // Same in-memory approach for a bumped supply reminder — quantity/threshold are the
  // only persisted state a supply has, and "remind me later" isn't a fact about either
  // of those, just a temporary UI suppression. Keyed by patient_supply id.
  final Map<int, DateTime> _supplySnoozes = {};

  // Same idea again for a bumped eye-care reminder. Keyed by vision_prescription id.
  final Map<int, DateTime> _eyeCareSnoozes = {};

  // Same idea again for a bumped metric reading reminder. Keyed by metric id.
  final Map<int, DateTime> _metricSnoozes = {};

  // Same idea again for a bumped therapy reminder. Keyed by care_order id.
  final Map<String, DateTime> _therapySnoozes = {};

  String? _patientUuid;
  List<Remindable> _reminders = [];
  Timer? _pollTimer;

  // Exposed so a special-cased reminder tile (see ReminderTile's SicknessRecheckReminder
  // handling) can open a screen that needs the patient context this registry already
  // tracks, without every caller having to thread it through separately.
  String? get patientUuid => _patientUuid;

  List<Remindable> get all => List.unmodifiable(_reminders);

  List<Remindable> get due {
    final List<Remindable> dueOnes = _reminders.where((r) => r.isDue).toList();
    dueOnes.sort((a, b) => a.nextReminder.compareTo(b.nextReminder));
    return dueOnes;
  }

  Future<void> loadForPatient(String patientUuid) async {
    _patientUuid = patientUuid;
    await refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    final String? patientUuid = _patientUuid;
    if (patientUuid == null) return;

    final List<Remindable> collected = [];
    collected.addAll(await _loadAppointmentReminders(patientUuid));
    collected.addAll(await _loadMedicationReminders(patientUuid));
    collected.addAll(await _loadSymptomRecheckReminders(patientUuid));
    collected.addAll(await _loadSicknessRecheckReminders(patientUuid));
    collected.addAll(await _loadQuestionnaireReminders(patientUuid));
    collected.addAll(await _loadImmunizationReminders(patientUuid));
    collected.addAll(await _loadTestReminders(patientUuid));
    collected.addAll(await _loadSupplyReminders(patientUuid));
    collected.addAll(await _loadEyeCareReminders(patientUuid));
    collected.addAll(await _loadMetricReminders(patientUuid));
    collected.addAll(await _loadTherapyReminders(patientUuid));
    collected.sort((a, b) => a.nextReminder.compareTo(b.nextReminder));

    _reminders = collected;
    notifyListeners();
  }

  // Runs the reminder's own persistence (the real record — dose log, appointment
  // status, resolved marker, received vaccination), handles the one case that needs
  // extra in-memory bookkeeping (a medication bump), then reloads everything fresh so
  // the UI reflects the consequence immediately rather than waiting for the next poll.
  Future<void> handleAction(
    Remindable reminder,
    ReminderAction action, {
    DateTime? bumpTo,
  }) async {
    await reminder.handleAction(action, bumpTo: bumpTo);
    if (reminder is MedicationReminder &&
        action == ReminderAction.bumped &&
        bumpTo != null) {
      _medicationSnoozes[reminder.medicationId] = bumpTo;
    }
    if (reminder is SupplyReminder &&
        action == ReminderAction.bumped &&
        bumpTo != null) {
      _supplySnoozes[reminder.supplyId] = bumpTo;
    }
    if (reminder is EyeCareReminder &&
        action == ReminderAction.bumped &&
        bumpTo != null) {
      _eyeCareSnoozes[reminder.prescriptionId] = bumpTo;
    }
    if (reminder is MetricReminder &&
        action == ReminderAction.bumped &&
        bumpTo != null) {
      _metricSnoozes[reminder.metricId] = bumpTo;
    }
    if (reminder is TherapyReminder &&
        action == ReminderAction.bumped &&
        bumpTo != null) {
      _therapySnoozes[reminder.careOrderId] = bumpTo;
    }
    await refresh();
  }

  // Removes a reminder from the current in-memory feed only, with no recorded
  // consequence — kept for callers that just want it out of view. Prefer handleAction
  // for anything the UI presents as a real choice (Done/Skipped/etc.).
  void dismiss(String remindableId) {
    _reminders.removeWhere((r) => r.remindableId == remindableId);
    notifyListeners();
  }

  Future<List<AppointmentReminder>> _loadAppointmentReminders(
    String patientUuid,
  ) async {
    final appointmentRows = await DatabaseManager().getAppointmentsForPatient(
      patientUuid,
    );
    if (appointmentRows.isEmpty) return const [];

    final providerRows = await DatabaseManager().getProviders(patientUuid);
    final Map<String, String> providerNames = {
      for (final row in providerRows)
        (row['provider_uuid'] as String):
            '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim(),
    };

    final DateTime now = DateTime.now();
    final List<AppointmentReminder> reminders = [];
    for (final row in appointmentRows) {
      final String status = (row['status'] as String?) ?? 'scheduled';
      if (status != 'scheduled')
        continue; // already handled (attended/missed) — not a reminder anymore

      final DateTime? scheduledFor = DateTime.tryParse(
        row['scheduled_for'] as String? ?? '',
      );
      if (scheduledFor == null || scheduledFor.isBefore(now))
        continue; // past and never actioned — not surfaced here
      reminders.add(
        AppointmentReminder(
          appointmentId: row['id'] as String,
          providerName: providerNames[row['provider_uuid']]?.isNotEmpty == true
              ? providerNames[row['provider_uuid']]!
              : 'your provider',
          scheduledFor: scheduledFor,
          reason: row['reason'] as String?,
        ),
      );
    }
    return reminders;
  }

  Future<List<MedicationReminder>> _loadMedicationReminders(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getMedicationsWithReminders(
      patientUuid,
    );
    if (rows.isEmpty) return const [];

    // Today's already-logged doses, so a dose just marked Done/Skipped doesn't
    // immediately resurface within its own grace window.
    final doseLogRows = await DatabaseManager().getTodaysMedicationDoseLog(
      patientUuid,
    );
    final Set<String> handledToday = {};
    for (final logRow in doseLogRows) {
      final DateTime? scheduledFor = DateTime.tryParse(
        logRow['scheduled_for'] as String? ?? '',
      );
      if (scheduledFor == null) continue;
      final String hhmm =
          '${scheduledFor.hour.toString().padLeft(2, '0')}:${scheduledFor.minute.toString().padLeft(2, '0')}';
      handledToday.add('${logRow['medication_id']}|$hhmm');
    }

    final DateTime now = DateTime.now();
    final List<MedicationReminder> reminders = [];

    for (final row in rows) {
      final String medicationId = row['id'] as String;

      DateTime? next;
      final DateTime? snoozeUntil = _medicationSnoozes[medicationId];
      if (snoozeUntil != null) {
        if (now.isBefore(snoozeUntil.add(const Duration(minutes: 1)))) {
          next = snoozeUntil;
        } else {
          _medicationSnoozes.remove(
            medicationId,
          ); // snooze has passed — fall back to the normal schedule
        }
      }

      if (next == null) {
        // A patient-chosen specific time (from the frequency screen's time picker)
        // takes priority over the frequency code's fixed defaults when one was set.
        final String? explicitTime = row['reminder_time'] as String?;
        final List<String> times =
            (explicitTime != null && explicitTime.isNotEmpty)
            ? [explicitTime]
            : FrequencySchedule.dailyTimesFor(row['freq'] as String?);
        next = _nextOccurrence(
          times,
          excludeTodayTimes: handledToday,
          medicationId: medicationId,
        );
      }
      if (next == null)
        continue; // e.g. PRN, unrecognized freq, or today's only slot already handled

      final Set<ReminderChannel> channels = {
        if ((row['chime_enabled'] as int? ?? 0) == 1) ReminderChannel.chime,
        if ((row['text_enabled'] as int? ?? 0) == 1) ReminderChannel.text,
        if ((row['email_enabled'] as int? ?? 0) == 1) ReminderChannel.email,
        if ((row['wearable_enabled'] as int? ?? 0) == 1)
          ReminderChannel.wearable,
      };

      WearableAlertMode? wearableMode;
      final String? rawMode = row['wearable_mode'] as String?;
      if (rawMode != null) {
        for (final mode in WearableAlertMode.values) {
          if (mode.name == rawMode) {
            wearableMode = mode;
            break;
          }
        }
      }

      reminders.add(
        MedicationReminder(
          medicationId: medicationId,
          patientUuid: patientUuid,
          medicationName: row['name'] as String,
          dose: row['dose'] as String?,
          doseTime: next,
          leadTime: Duration(minutes: (row['lead_minutes'] as int?) ?? 0),
          reminderChannels: channels,
          reminderWearableMode: wearableMode,
        ),
      );
    }
    return reminders;
  }

  // Same shape as _loadMedicationReminders, with one simplification: care_order_
  // acknowledgment has no per-slot "scheduled_for" the way medication_dose_log does
  // (it's just "acknowledged now"), so any acknowledgment today suppresses the whole
  // day's reminder rather than just one slot — the same all-or-nothing semantics the
  // Due tab's checklist already has for care orders.
  Future<List<TherapyReminder>> _loadTherapyReminders(String patientUuid) async {
    final rows = await DatabaseManager().getCareOrdersWithReminders(patientUuid);
    if (rows.isEmpty) return const [];

    final Set<String> handledToday = (await DatabaseManager().getTodaysCareOrderAcknowledgments(patientUuid)).toSet();

    final DateTime now = DateTime.now();
    final List<TherapyReminder> reminders = [];

    for (final row in rows) {
      final String careOrderId = row['id'] as String;
      if (handledToday.contains(careOrderId)) continue;

      DateTime? next;
      final DateTime? snoozeUntil = _therapySnoozes[careOrderId];
      if (snoozeUntil != null) {
        if (now.isBefore(snoozeUntil.add(const Duration(minutes: 1)))) {
          next = snoozeUntil;
        } else {
          _therapySnoozes.remove(careOrderId);
        }
      }

      if (next == null) {
        final String? explicitTime = row['reminder_time'] as String?;
        final List<String> times = (explicitTime != null && explicitTime.isNotEmpty)
            ? [explicitTime]
            : FrequencySchedule.dailyTimesFor(row['freq_code'] as String?);
        next = _nextOccurrence(times, medicationId: careOrderId);
      }
      if (next == null) continue; // e.g. PRN-style/no recognized schedule

      final Set<ReminderChannel> channels = {
        if ((row['chime_enabled'] as int? ?? 0) == 1) ReminderChannel.chime,
        if ((row['text_enabled'] as int? ?? 0) == 1) ReminderChannel.text,
        if ((row['email_enabled'] as int? ?? 0) == 1) ReminderChannel.email,
        if ((row['wearable_enabled'] as int? ?? 0) == 1) ReminderChannel.wearable,
      };

      WearableAlertMode? wearableMode;
      final String? rawMode = row['wearable_mode'] as String?;
      if (rawMode != null) {
        for (final mode in WearableAlertMode.values) {
          if (mode.name == rawMode) {
            wearableMode = mode;
            break;
          }
        }
      }

      reminders.add(
        TherapyReminder(
          careOrderId: careOrderId,
          patientUuid: patientUuid,
          label: row['label'] as String,
          directions: row['directions'] as String?,
          dueAt: next,
          leadTime: Duration(minutes: (row['lead_minutes'] as int?) ?? 0),
          reminderChannels: channels,
          reminderWearableMode: wearableMode,
        ),
      );
    }
    return reminders;
  }

  Future<List<SymptomRecheckReminder>> _loadSymptomRecheckReminders(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getMarkersDueForFollowUp(patientUuid);
    final List<SymptomRecheckReminder> reminders = [];
    for (final row in rows) {
      final BodyMarker marker = BodyMarker.fromRow(row);
      if (marker.id == null) continue;
      final DateTime baseline =
          marker.lastCheckedAt ??
          DateTime.fromMillisecondsSinceEpoch(marker.recorded * 1000);
      reminders.add(
        SymptomRecheckReminder(
          markerId: marker.id!,
          bodyPart: marker.name,
          dueAt: baseline.add(const Duration(days: 3)),
        ),
      );
    }
    return reminders;
  }

  Future<List<SicknessRecheckReminder>> _loadSicknessRecheckReminders(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getSicknessEpisodesDueForRecheck(patientUuid);
    final List<SicknessRecheckReminder> reminders = [];
    for (final row in rows) {
      final SicknessEpisode episode = SicknessEpisode.fromRow(row);
      final DateTime baseline = episode.lastCheckedAt ?? episode.startedAt;
      reminders.add(
        SicknessRecheckReminder(
          episodeId: episode.id,
          symptoms: episode.symptoms,
          startedAt: episode.startedAt,
          dueAt: baseline.add(const Duration(days: 1)),
        ),
      );
    }
    return reminders;
  }

  // "if they don't fill it out the same day" — due starting the day after it
  // arrived, then daily until it's answered (see QuestionnaireReminder's doc comment
  // for why there's no way to dismiss this except by actually answering it).
  Future<List<QuestionnaireReminder>> _loadQuestionnaireReminders(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getActiveAssignedQuestionnaires(patientUuid);
    final List<QuestionnaireReminder> reminders = [];
    for (final row in rows) {
      final DateTime assignedAt = DateTime.parse(row['assigned_at'] as String);
      reminders.add(
        QuestionnaireReminder(
          assignmentId: row['id'] as String,
          templateId: row['template_id'] as String,
          providerName: row['provider_name'] as String,
          assignedAt: assignedAt,
          dueAt: assignedAt.add(const Duration(days: 1)),
        ),
      );
    }
    return reminders;
  }

  Future<List<ImmunizationReminder>> _loadImmunizationReminders(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getVaccinationsWithReminders(
      patientUuid,
    );
    final List<ImmunizationReminder> reminders = [];
    for (final row in rows) {
      final DateTime? dueDate = DateTime.tryParse(
        row['next_due'] as String? ?? '',
      );
      if (dueDate == null) continue;
      reminders.add(
        ImmunizationReminder(
          vaccinationId: row['id'] as int,
          vaccineName: row['name'] as String,
          dueDate: dueDate,
        ),
      );
    }
    return reminders;
  }

  Future<List<TestReminder>> _loadTestReminders(String patientUuid) async {
    final rows = await DatabaseManager().getTestsWithReminders(patientUuid);
    final List<TestReminder> reminders = [];
    for (final row in rows) {
      final DateTime? dueDate = DateTime.tryParse(
        row['next_due'] as String? ?? '',
      );
      if (dueDate == null) continue;
      reminders.add(
        TestReminder(
          testId: row['id'] as int,
          testName: row['name'] as String,
          category: row['category'] as String?,
          dueDate: dueDate,
        ),
      );
    }
    return reminders;
  }

  Future<List<SupplyReminder>> _loadSupplyReminders(String patientUuid) async {
    final rows = await DatabaseManager().getLowSupplies(patientUuid);
    final DateTime now = DateTime.now();
    final List<SupplyReminder> reminders = [];
    for (final row in rows) {
      final int id = row['id'] as int;
      final DateTime? snoozeUntil = _supplySnoozes[id];
      if (snoozeUntil != null) {
        if (now.isBefore(snoozeUntil))
          continue; // still snoozed — skip this refresh
        _supplySnoozes.remove(id); // snooze has passed
      }
      reminders.add(
        SupplyReminder(
          supplyId: id,
          supplyName: row['name'] as String,
          category: row['category'] as String?,
        ),
      );
    }
    return reminders;
  }

  // Only the most recent record per type (glasses/contacts) can ever be "current" — an
  // old, already-superseded prescription shouldn't also nag once a newer one exists.
  // Rows arrive latest-first (getVisionPrescriptionsForPatient orders by issued_date
  // DESC), so the first row seen per type is the one that matters.
  Future<List<EyeCareReminder>> _loadEyeCareReminders(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getVisionPrescriptionsForPatient(
      patientUuid,
    );
    final Set<int> seenTypes = {};
    final DateTime now = DateTime.now();
    final List<EyeCareReminder> reminders = [];

    for (final row in rows) {
      final int typeIndex = row['type'] as int? ?? 0;
      if (!seenTypes.add(typeIndex))
        continue; // already have the latest of this type

      final DateTime? expiryDate = row['expiry_date'] != null
          ? DateTime.tryParse(row['expiry_date'] as String)
          : null;
      if (expiryDate == null) continue;

      final int id = row['id'] as int;
      final DateTime? snoozeUntil = _eyeCareSnoozes[id];
      if (snoozeUntil != null) {
        if (now.isBefore(snoozeUntil)) continue;
        _eyeCareSnoozes.remove(id);
      }

      reminders.add(
        EyeCareReminder(
          prescriptionId: id,
          type: VisionPrescriptionType.values[typeIndex],
          expiryDate: expiryDate,
        ),
      );
    }
    return reminders;
  }

  // Next due = the patient's last real reading + their chosen cadence, with the
  // chosen time-of-day applied — the metric equivalent of MedicationReminder's
  // dose-log exclusion, but generalized to any interval instead of hardcoded to "today"
  // (a metric's cadence can be weekly or monthly, where "already handled today" isn't
  // the right question). Never having logged a reading at all counts as due now, so an
  // enabled reminder actually nudges a patient to start rather than waiting a full
  // cadence period before ever firing once.
  Future<List<MetricReminder>> _loadMetricReminders(String patientUuid) async {
    final rows = await DatabaseManager().getMetricsWithReminders(patientUuid);
    final DateTime now = DateTime.now();
    final List<MetricReminder> reminders = [];

    for (final row in rows) {
      final int metricId = row['metric_id'] as int;

      final DateTime? snoozeUntil = _metricSnoozes[metricId];
      if (snoozeUntil != null) {
        if (now.isBefore(snoozeUntil)) continue;
        _metricSnoozes.remove(metricId);
      }

      final String rawCadence =
          (row['cadence'] as String?) ?? MetricReminderCadence.daily.name;
      MetricReminderCadence cadence = MetricReminderCadence.daily;
      for (final c in MetricReminderCadence.values) {
        if (c.name == rawCadence) {
          cadence = c;
          break;
        }
      }

      final DateTime? lastMeasured = row['last_measured'] != null
          ? DateTime.tryParse(row['last_measured'] as String)
          : null;
      final DateTime base = lastMeasured ?? now.subtract(cadence.interval);
      DateTime due = base.add(cadence.interval);

      final String? reminderTime = row['reminder_time'] as String?;
      if (reminderTime != null && reminderTime.contains(':')) {
        final List<String> parts = reminderTime.split(':');
        final int? hour = int.tryParse(parts[0]);
        final int? minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
        if (hour != null && minute != null) {
          due = DateTime(due.year, due.month, due.day, hour, minute);
        }
      }

      final Set<ReminderChannel> channels = {
        if ((row['chime_enabled'] as int? ?? 0) == 1) ReminderChannel.chime,
        if ((row['text_enabled'] as int? ?? 0) == 1) ReminderChannel.text,
        if ((row['email_enabled'] as int? ?? 0) == 1) ReminderChannel.email,
        if ((row['wearable_enabled'] as int? ?? 0) == 1)
          ReminderChannel.wearable,
      };

      WearableAlertMode? wearableMode;
      final String? rawMode = row['wearable_mode'] as String?;
      if (rawMode != null) {
        for (final mode in WearableAlertMode.values) {
          if (mode.name == rawMode) {
            wearableMode = mode;
            break;
          }
        }
      }

      reminders.add(
        MetricReminder(
          metricId: metricId,
          patientUuid: patientUuid,
          metricName: row['name'] as String,
          dueAt: due,
          cadenceInterval: cadence.interval,
          reminderChannels: channels,
          reminderWearableMode: wearableMode,
        ),
      );
    }
    return reminders;
  }

  // A dose that was due a few minutes ago is still relevant — it shouldn't vanish the
  // instant its exact minute passes, only jump straight to tomorrow. Kept within this
  // grace window before rolling forward.
  static const Duration _recentGrace = Duration(minutes: 60);

  // Finds the nearest upcoming "HH:mm" from today's remaining times, or tomorrow's
  // first one if today's have all already passed — unless a time within the last
  // [_recentGrace] is still more relevant than waiting for the next occurrence.
  // [excludeTodayTimes] skips today's slots that already have a dose-log entry
  // ("medicationId|HH:mm"), so a just-logged dose doesn't immediately resurface.
  DateTime? _nextOccurrence(
    List<String> dailyTimes, {
    Set<String> excludeTodayTimes = const {},
    String? medicationId,
  }) {
    if (dailyTimes.isEmpty) return null;
    final DateTime now = DateTime.now();

    DateTime? soonestFuture;
    DateTime? mostRecentPast;

    for (int dayOffset = -1; dayOffset <= 1; dayOffset++) {
      final DateTime day = now.add(Duration(days: dayOffset));
      for (final String raw in dailyTimes) {
        if (dayOffset == 0 &&
            medicationId != null &&
            excludeTodayTimes.contains('$medicationId|$raw')) {
          continue; // already logged for today
        }

        final List<String> parts = raw.split(':');
        if (parts.length != 2) continue;
        final int? hour = int.tryParse(parts[0]);
        final int? minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final DateTime candidate = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          minute,
        );
        if (candidate.isAfter(now)) {
          if (soonestFuture == null || candidate.isBefore(soonestFuture))
            soonestFuture = candidate;
        } else {
          if (mostRecentPast == null || candidate.isAfter(mostRecentPast))
            mostRecentPast = candidate;
        }
      }
    }

    if (mostRecentPast != null &&
        now.difference(mostRecentPast) <= _recentGrace) {
      return mostRecentPast;
    }
    return soonestFuture;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
