import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'database_manager.dart';
import 'medical_test.dart';
import 'domain_colors.dart';
import 'medication_services.dart';
import 'schedulable.dart';
import 'vision_prescription.dart';

// What a person can do in response to a reminder. This exists specifically because a
// swipe that just hides a card isn't a record — a missed appointment, skipped dose, or
// missed immunization needs to actually be recorded, not silently disappear, since it
// may need to be reported to a physician.
enum ReminderAction { done, skipped, muted, bumped }

extension ReminderActionDetails on ReminderAction {
  String get label {
    switch (this) {
      case ReminderAction.done:
        return "Done";
      case ReminderAction.skipped:
        return "Skipped This Time";
      case ReminderAction.muted:
        return "Don't Remind Me Again";
      case ReminderAction.bumped:
        return "Bump to a New Time";
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderAction.done:
        return Symbols.check_circle;
      case ReminderAction.skipped:
        return Symbols.cancel;
      case ReminderAction.muted:
        return Symbols.notifications_off;
      case ReminderAction.bumped:
        return Symbols.schedule;
    }
  }
}

// Anything that can be surfaced to the patient as "this is coming up" implements this
// — appointments, medication doses, symptom recheck prompts, immunizations due, and
// (later, once that data model exists) lab/test due dates and self-tracked metrics.
abstract interface class Remindable {
  String
  get remindableId; // stable key for dismiss/dedupe, e.g. "medication:<id>:<time>"
  String get title;
  String get subtitle;
  IconData get icon;
  // Same domain-identity color as the reminder's own hub tile (see domain_colors.dart)
  // — without this, every reminder in the sheet rendered the same interactive blue
  // regardless of type, which is exactly the "information mud" a color system is
  // supposed to prevent: nothing distinguished a medication reminder from a supply
  // reminder except reading the text.
  Color get color;
  DateTime get nextReminder; // the actual target/event time, not when to alert
  Duration
  get advanceNotice; // how far ahead of nextReminder this should start surfacing
  Duration?
  get cadence; // null = one-time; otherwise roughly how often it repeats
  Set<ReminderChannel> get channels;
  WearableAlertMode? get wearableMode;
  bool get isDue;

  // Which responses make sense for this kind of reminder — not every action applies to
  // every type (a one-time appointment has nothing to "mute", for instance).
  List<ReminderAction> get availableActions;

  // Persists the consequence of the chosen action. `bumpTo` is required for
  // ReminderAction.bumped and ignored otherwise.
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo});
}

// `implements` doesn't inherit a default body the way `extends` would, so each
// concrete Remindable below delegates its `isDue` here instead of repeating the logic.
bool isRemindableDue(Remindable reminder) {
  return DateTime.now().isAfter(
    reminder.nextReminder.subtract(reminder.advanceNotice),
  );
}

class AppointmentReminder implements Remindable {
  final String appointmentId;
  final String providerName;
  final DateTime scheduledFor;
  final String? reason;

  const AppointmentReminder({
    required this.appointmentId,
    required this.providerName,
    required this.scheduledFor,
    this.reason,
  });

  @override
  String get remindableId => 'appointment:$appointmentId';
  @override
  String get title {
    final String reasonPart = (reason != null && reason!.isNotEmpty)
        ? ' re $reason'
        : '';
    return 'You have an appointment with $providerName$reasonPart ${_relativeDay(scheduledFor)} at ${_formatTime(scheduledFor)}';
  }

  @override
  String get subtitle => _formatWhen(scheduledFor);
  // Same icon as the Caregivers tab on the bottom nav bar (home_screen.dart) — a
  // caregiver appointment should read as unmistakably "the providers thing" at a
  // glance, not a generic calendar icon.
  @override
  IconData get icon => Symbols.diversity_4;
  @override
  Color get color => AppDomain.careTeam.color;
  @override
  DateTime get nextReminder => scheduledFor;
  // No per-appointment reminder preference exists yet (the appointment table has no
  // channel/lead-time columns) — a sensible fixed default until that's built.
  @override
  Duration get advanceNotice => const Duration(hours: 24);
  @override
  Duration? get cadence => null;
  @override
  Set<ReminderChannel> get channels => const {ReminderChannel.chime};
  @override
  WearableAlertMode? get wearableMode => null;
  @override
  bool get isDue => isRemindableDue(this);

  // No "mute" — there's no recurring reminder on a one-time appointment to silence.
  @override
  List<ReminderAction> get availableActions => const [
    ReminderAction.done,
    ReminderAction.skipped,
    ReminderAction.bumped,
  ];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.done:
        await DatabaseManager().updateAppointmentStatus(
          appointmentId,
          'attended',
        );
      case ReminderAction.skipped:
        await DatabaseManager().updateAppointmentStatus(
          appointmentId,
          'missed',
        );
      case ReminderAction.bumped:
        if (bumpTo != null) {
          await DatabaseManager().rescheduleAppointment(appointmentId, bumpTo);
        }
      case ReminderAction.muted:
        break; // not offered — see availableActions
    }
  }
}

class MedicationReminder implements Remindable {
  final String medicationId;
  final String patientUuid;
  final String medicationName;
  final String? dose;
  final DateTime doseTime;
  final Duration leadTime;
  final Set<ReminderChannel> reminderChannels;
  final WearableAlertMode? reminderWearableMode;

  const MedicationReminder({
    required this.medicationId,
    required this.patientUuid,
    required this.medicationName,
    this.dose,
    required this.doseTime,
    required this.leadTime,
    required this.reminderChannels,
    this.reminderWearableMode,
  });

  @override
  String get remindableId =>
      'medication:$medicationId:${doseTime.toIso8601String()}';
  @override
  String get title => 'Take $medicationName';
  @override
  String get subtitle => dose != null && dose!.isNotEmpty
      ? 'Dose: $dose'
      : "It's time for your dose";
  // Same icon as the Medications tab on the bottom nav bar (home_screen.dart) — already
  // matched before this pass, kept as the reference point for the other four.
  @override
  IconData get icon => Symbols.medication;
  @override
  Color get color => AppDomain.prescriptions.color;
  @override
  DateTime get nextReminder => doseTime;
  @override
  Duration get advanceNotice => leadTime;
  // Approximate — the underlying schedule is re-derived from `freq`/`reminder_time` on
  // every refresh rather than truly recurring state, but conceptually this repeats daily.
  @override
  Duration? get cadence => const Duration(days: 1);
  @override
  Set<ReminderChannel> get channels => reminderChannels;
  @override
  WearableAlertMode? get wearableMode => reminderWearableMode;
  @override
  bool get isDue => isRemindableDue(this);

  @override
  List<ReminderAction> get availableActions => ReminderAction.values;

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.done:
        await DatabaseManager().logMedicationDose(
          medicationId: medicationId,
          patientUuid: patientUuid,
          scheduledFor: doseTime,
          status: 'taken',
        );
      case ReminderAction.skipped:
        await DatabaseManager().logMedicationDose(
          medicationId: medicationId,
          patientUuid: patientUuid,
          scheduledFor: doseTime,
          status: 'skipped',
        );
      case ReminderAction.muted:
        await DatabaseManager().muteMedicationReminder(medicationId);
      case ReminderAction.bumped:
        // Nothing to persist here — a medication's next-reminder time is re-derived
        // fresh from its frequency schedule on every refresh, there's no "snoozed
        // until" column to write to. ReminderRegistry tracks this one in memory
        // instead, right after calling this method.
        break;
    }
  }
}

// A metric reading has no honest one-tap "done" the way a dose or an appointment does —
// "done" would need a real value, which isn't something a swipe or a generic action-sheet
// tap can supply. Same reasoning as SupplyReminder: only muted/bumped are offered, and
// the actual reading still has to happen on the Metrics screen itself. `dueAt` is computed
// from the patient's last real reading + the chosen cadence (see
// ReminderRegistry._loadMetricReminders) rather than a fixed daily slot, so it works the
// same way regardless of whether the cadence is daily, weekly, or monthly.
class MetricReminder implements Remindable {
  final int metricId;
  final String patientUuid;
  final String metricName;
  final DateTime dueAt;
  final Duration cadenceInterval;
  final Set<ReminderChannel> reminderChannels;
  final WearableAlertMode? reminderWearableMode;

  const MetricReminder({
    required this.metricId,
    required this.patientUuid,
    required this.metricName,
    required this.dueAt,
    required this.cadenceInterval,
    required this.reminderChannels,
    this.reminderWearableMode,
  });

  @override
  String get remindableId => 'metric:$metricId';
  @override
  String get title => 'Log your $metricName reading';
  @override
  String get subtitle => "It's time to take a reading";
  // Same icon as the Metrics tab on the bottom nav bar (home_screen.dart).
  @override
  IconData get icon => Symbols.health_metrics;
  @override
  Color get color => AppDomain.metrics.color;
  @override
  DateTime get nextReminder => dueAt;
  // dueAt already accounts for the cadence — nothing to lead ahead of, same reasoning as
  // SymptomRecheckReminder.
  @override
  Duration get advanceNotice => Duration.zero;
  @override
  Duration? get cadence => cadenceInterval;
  @override
  Set<ReminderChannel> get channels => reminderChannels;
  @override
  WearableAlertMode? get wearableMode => reminderWearableMode;
  @override
  bool get isDue => isRemindableDue(this);

  @override
  List<ReminderAction> get availableActions => const [
    ReminderAction.muted,
    ReminderAction.bumped,
  ];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.muted:
        await DatabaseManager().muteMetricReminder(
          metricId: metricId,
          patientUuid: patientUuid,
        );
      case ReminderAction.bumped:
        break; // Nothing to persist — ReminderRegistry tracks the snooze in memory,
      // same as MedicationReminder/SupplyReminder.
      case ReminderAction.done:
      case ReminderAction.skipped:
        break; // not offered — see availableActions
    }
  }
}

class SymptomRecheckReminder implements Remindable {
  final int markerId;
  final String bodyPart;
  final DateTime dueAt;

  const SymptomRecheckReminder({
    required this.markerId,
    required this.bodyPart,
    required this.dueAt,
  });

  @override
  String get remindableId => 'symptom:$markerId';
  @override
  String get title => 'Check in: $bodyPart';
  @override
  String get subtitle => 'Is this still bothering you?';
  // Same icon as the Symptoms action tile (medical_profile_screen.dart).
  @override
  IconData get icon => Symbols.symptoms;
  @override
  Color get color => AppDomain.symptoms.color;
  @override
  DateTime get nextReminder => dueAt;
  // Already computed as "due" by the query that finds it — nothing to wait for.
  @override
  Duration get advanceNotice => Duration.zero;
  @override
  Duration? get cadence => null;
  @override
  Set<ReminderChannel> get channels => const {ReminderChannel.chime};
  @override
  WearableAlertMode? get wearableMode => null;
  @override
  bool get isDue => isRemindableDue(this);

  // Uses the same generic action sheet as every other Remindable, mapped onto the
  // same "better"/"still bothering me" choices the dedicated SymptomFollowUpDialog
  // (shown separately when opening the Symptoms screen directly) offers — kept simple
  // and consistent rather than special-casing this type's tap behavior.
  @override
  List<ReminderAction> get availableActions => const [
    ReminderAction.done,
    ReminderAction.skipped,
  ];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.done:
        await DatabaseManager().resolveBodyMarker(markerId);
      case ReminderAction.skipped:
        await DatabaseManager().markBodyMarkerChecked(markerId);
      case ReminderAction.muted:
      case ReminderAction.bumped:
        break; // not offered — see availableActions
    }
  }
}

class ImmunizationReminder implements Remindable {
  final int vaccinationId;
  final String vaccineName;
  final DateTime dueDate;

  const ImmunizationReminder({
    required this.vaccinationId,
    required this.vaccineName,
    required this.dueDate,
  });

  @override
  String get remindableId => 'immunization:$vaccinationId';
  @override
  String get title => 'Immunization due: $vaccineName';
  @override
  String get subtitle => 'Due ${_formatWhen(dueDate)}';
  // Same icon as the Immunizations action tile (medical_profile_screen.dart). Plain
  // (Outlined) variant, not "_sharp" — the Sharp glyph for this icon renders as a blank
  // space on Android release builds despite the font subset containing the codepoint;
  // every other tile on that screen already uses a non-"_sharp" icon successfully.
  @override
  IconData get icon => Symbols.vaccines;
  @override
  Color get color => AppDomain.immunizations.color;
  @override
  DateTime get nextReminder => dueDate;
  @override
  Duration get advanceNotice => const Duration(days: 7); // a week's notice to book it
  @override
  Duration? get cadence => null;
  @override
  Set<ReminderChannel> get channels => const {ReminderChannel.chime};
  @override
  WearableAlertMode? get wearableMode => null;
  @override
  bool get isDue => isRemindableDue(this);

  // No "skipped" — this app doesn't have a separate immunization-history log to record
  // a distinct "chose not to" event against (unlike medication doses). "Done" or
  // "bump the due date" are the two honest options with this schema.
  @override
  List<ReminderAction> get availableActions => const [
    ReminderAction.done,
    ReminderAction.bumped,
  ];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.done:
        await DatabaseManager().markVaccinationReceived(
          vaccinationId,
          DateTime.now(),
        );
      case ReminderAction.bumped:
        if (bumpTo != null) {
          await DatabaseManager().rescheduleVaccinationReminder(
            vaccinationId,
            bumpTo,
          );
        }
      case ReminderAction.skipped:
      case ReminderAction.muted:
        break; // not offered — see availableActions
    }
  }
}

// Built directly against Schedulable (not retrofitted) — this is new code, so it can
// satisfy both contracts from the start rather than needing every existing Remindable
// updated at once.
class TestReminder implements Remindable, Schedulable {
  final int testId;
  final String testName;
  final String? category;
  final DateTime dueDate;

  const TestReminder({
    required this.testId,
    required this.testName,
    this.category,
    required this.dueDate,
  });

  @override
  String get remindableId => 'test:$testId';
  @override
  String get title => 'Schedule: $testName';
  @override
  String get subtitle => 'Due ${_formatWhen(dueDate)}';
  // Same category-specific icon the Tests screen uses (see iconForTestCategory) — a
  // cardiology reminder looks like cardiology, not a generic "test" glyph.
  @override
  IconData get icon => iconForTestCategory(category);
  @override
  Color get color => AppDomain.tests.color;
  @override
  DateTime get nextReminder => dueDate;
  @override
  DateTime get occursAt => dueDate; // Schedulable/Temporal
  // Every test is out-of-house now — needs real lead time to actually book it.
  @override
  Duration get advanceNotice => const Duration(days: 7);
  @override
  Duration? get cadence => null; // recurrence isn't modeled yet — same as Appointment/Immunization
  @override
  Set<ReminderChannel> get channels => const {ReminderChannel.chime};
  @override
  WearableAlertMode? get wearableMode => null;
  @override
  bool get isDue => isRemindableDue(this);

  // No "skipped" — same reasoning as ImmunizationReminder: there's no dedicated
  // history log to record a distinct "chose not to" event against.
  @override
  List<ReminderAction> get availableActions => const [
    ReminderAction.done,
    ReminderAction.bumped,
  ];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.done:
        await DatabaseManager().markTestDone(testId, DateTime.now());
      case ReminderAction.bumped:
        if (bumpTo != null) {
          await DatabaseManager().rescheduleTestReminder(testId, bumpTo);
        }
      case ReminderAction.skipped:
      case ReminderAction.muted:
        break; // not offered — see availableActions
    }
  }
}

// Unlike every other Remindable, this isn't scheduled against a date at all — a
// supply doesn't "come due," it either has enough on hand or it doesn't. Only ever
// constructed for a supply already at/under its reorder threshold (see
// DatabaseManager.getLowSupplies), so isDue is hard-coded true rather than delegating
// to isRemindableDue: there's no future instant to wait for, the condition that makes
// this relevant already happened by the time this object exists. nextReminder is set
// to "now" purely so sorting/display code that expects a DateTime has one to use.
//
// No `done` action, deliberately: the honest fix is entering the real new quantity on
// the Supplies screen, and fabricating some default restocked count on a one-tap swipe
// would just be a made-up number. `muted` instead zeroes the reorder threshold — "only
// tell me if I'm completely out" — which is an honest thing to promise without knowing
// the real count.
class SupplyReminder implements Remindable {
  final int supplyId;
  final String supplyName;
  final String? category;

  const SupplyReminder({
    required this.supplyId,
    required this.supplyName,
    this.category,
  });

  @override
  String get remindableId => 'supply:$supplyId';
  @override
  String get title => 'Running low: $supplyName';
  @override
  String get subtitle => "Time to reorder";
  // Same icon as the Supplies action tile (medical_profile_screen.dart).
  @override
  IconData get icon => Symbols.inventory_2;
  @override
  Color get color => AppDomain.supplies.color;
  @override
  DateTime get nextReminder => DateTime.now();
  @override
  Duration get advanceNotice => Duration.zero;
  @override
  Duration? get cadence => null;
  @override
  Set<ReminderChannel> get channels => const {ReminderChannel.chime};
  @override
  WearableAlertMode? get wearableMode => null;
  @override
  bool get isDue => true;

  @override
  List<ReminderAction> get availableActions => const [
    ReminderAction.muted,
    ReminderAction.bumped,
  ];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    switch (action) {
      case ReminderAction.muted:
        await DatabaseManager().updateSupplyThreshold(supplyId, 0);
      case ReminderAction.bumped:
        break; // Nothing to persist — ReminderRegistry tracks the snooze in memory,
      // same as MedicationReminder.
      case ReminderAction.done:
      case ReminderAction.skipped:
        break; // not offered — see availableActions
    }
  }
}

// Unlike ImmunizationReminder, there's no "mark received" action here — the honest fix
// for an expiring prescription is a brand new eye exam producing a brand new
// VisionPrescription record, not flipping a flag on the old one. Once that new record
// exists (with its own later expiry), this reminder simply stops being generated on the
// next refresh — nothing to explicitly resolve. So the only real action is `bumped`
// ("remind me later," e.g. once the exam is actually booked); no `done`, no `muted`.
class EyeCareReminder implements Remindable {
  final int prescriptionId;
  final VisionPrescriptionType type;
  final DateTime expiryDate;

  const EyeCareReminder({
    required this.prescriptionId,
    required this.type,
    required this.expiryDate,
  });

  @override
  String get remindableId => 'vision:$prescriptionId';
  @override
  String get title => expiryDate.isBefore(DateTime.now())
      ? '${type.label} prescription has expired'
      : '${type.label} prescription expiring soon';
  @override
  String get subtitle => 'Time to book an eye exam';
  // Same icon as the Eye Care action tile (medical_profile_screen.dart).
  @override
  IconData get icon => Symbols.ophthalmology;
  @override
  Color get color => AppDomain.eyeCare.color;
  @override
  DateTime get nextReminder => expiryDate;
  @override
  Duration get advanceNotice => const Duration(days: 14);
  @override
  Duration? get cadence => null;
  @override
  Set<ReminderChannel> get channels => const {ReminderChannel.chime};
  @override
  WearableAlertMode? get wearableMode => null;
  @override
  bool get isDue => isRemindableDue(this);

  @override
  List<ReminderAction> get availableActions => const [ReminderAction.bumped];

  @override
  Future<void> handleAction(ReminderAction action, {DateTime? bumpTo}) async {
    // bumped: nothing to persist — ReminderRegistry tracks the snooze in memory, same
    // as MedicationReminder/SupplyReminder. Nothing else is offered — see
    // availableActions.
  }
}

String _formatWhen(DateTime when) {
  final String hh = when.hour.toString().padLeft(2, '0');
  final String mm = when.minute.toString().padLeft(2, '0');
  return '${when.month}/${when.day} at $hh:$mm';
}

// "today"/"tomorrow" reads naturally in a reminder sentence right up until it doesn't
// — anything further out falls back to a plain date rather than "in 5 days", which
// would need pluralization handling for no real benefit here.
String _relativeDay(DateTime when) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime target = DateTime(when.year, when.month, when.day);
  final int dayDiff = target.difference(today).inDays;
  if (dayDiff == 0) return "today";
  if (dayDiff == 1) return "tomorrow";
  return "${when.month}/${when.day}";
}

String _formatTime(DateTime when) {
  final int hour12 = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final String mm = when.minute.toString().padLeft(2, '0');
  final String ampm = when.hour < 12 ? "AM" : "PM";
  return '$hour12:$mm $ampm';
}
