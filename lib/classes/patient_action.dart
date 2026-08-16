import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'listable.dart';
import 'patient_sentiment.dart';

abstract interface class Actionable implements Listable {
  IconData get icon;
  late DateTime? ended;
  Duration get duration;
}

enum PatientActionTypes implements Listable {
  measured,
  dosed,
  exercised,
  changedMood,
  symptomLogged,
  appointmentAttended,
  testCompleted;

  @override
  String get description {
    switch (this) {
      case PatientActionTypes.measured:
        return "Measured something";
      case PatientActionTypes.dosed:
        return "Took some medication";
      case PatientActionTypes.exercised:
        return "Took some form of exercise";
      case PatientActionTypes.changedMood:
        return "Registered how I feel";
      case PatientActionTypes.symptomLogged:
        return "Logged a symptom";
      case PatientActionTypes.appointmentAttended:
        return "Had an appointment";
      case PatientActionTypes.testCompleted:
        return "Completed a test";
    }
  }

  @override
  String get label {
    switch (this) {
      case PatientActionTypes.measured:
        return "Measured";
      case PatientActionTypes.dosed:
        return "Took Medication";
      case PatientActionTypes.exercised:
        return "Exercised";
      case PatientActionTypes.changedMood:
        return "Felt";
      case PatientActionTypes.symptomLogged:
        return "Symptom";
      case PatientActionTypes.appointmentAttended:
        return "Appointment";
      case PatientActionTypes.testCompleted:
        return "Test";
    }
  }

  // Matches the icon already established for this same concept elsewhere in the app
  // (AppointmentReminder, TestReminder, the Symptoms tile) — a dot on the timeline
  // should read as unmistakably "the same thing" as its icon everywhere else, not a
  // second, different glyph for the identical concept.
  IconData get icon {
    switch (this) {
      case PatientActionTypes.measured:
        return Symbols.measuring_tape;
      case PatientActionTypes.dosed:
        return Symbols.medication_liquid;
      case PatientActionTypes.exercised:
        return Symbols.exercise;
      case PatientActionTypes.changedMood:
        return Symbols.mood;
      case PatientActionTypes.symptomLogged:
        return Symbols.symptoms;
      case PatientActionTypes.appointmentAttended:
        return Symbols.diversity_4;
      case PatientActionTypes.testCompleted:
        return Symbols.lab_panel;
    }
  }
}

// A single dot on the timeline. `occurred` used to fall back to a random timestamp
// whenever `started` wasn't set — meaning the mock data literally re-randomized itself
// on every rebuild, which is exactly the "changes every time you look at the screen"
// problem flagged directly. Making `occurred` a required, real timestamp makes that bug
// impossible to reintroduce rather than just fixing today's call sites.
class PatientAction implements Actionable {
  final PatientActionTypes actionType;
  final DateTime occurred;
  @override
  DateTime? ended;
  final String? detail;

  PatientAction({required this.actionType, required this.occurred, this.ended, this.detail});

  factory PatientAction.medicationDose(Map<String, dynamic> row) {
    return PatientAction(
      actionType: PatientActionTypes.dosed,
      occurred: DateTime.parse(row['scheduled_for'] as String),
      detail: 'Took ${row['medication_name']}',
    );
  }

  factory PatientAction.appointment(Map<String, dynamic> row) {
    final String? reason = row['reason'] as String?;
    final String provider = (row['provider_name'] as String?) ?? 'your provider';
    return PatientAction(
      actionType: PatientActionTypes.appointmentAttended,
      occurred: DateTime.parse(row['scheduled_for'] as String),
      detail: 'Appointment with $provider${reason != null && reason.isNotEmpty ? ' — $reason' : ''}',
    );
  }

  factory PatientAction.symptom(Map<String, dynamic> row) {
    return PatientAction(
      actionType: PatientActionTypes.symptomLogged,
      occurred: DateTime.fromMillisecondsSinceEpoch((row['recorded'] as int) * 1000),
      detail: 'Symptom: ${row['zone_name']}',
    );
  }

  factory PatientAction.mood(Map<String, dynamic> row) {
    final Sentiment mood = Sentiment.values[row['mood'] as int];
    return PatientAction(
      actionType: PatientActionTypes.changedMood,
      occurred: DateTime.parse(row['start_date'] as String),
      detail: 'Mood changed to ${mood.label}',
    );
  }

  factory PatientAction.test(Map<String, dynamic> row) {
    return PatientAction(
      actionType: PatientActionTypes.testCompleted,
      occurred: DateTime.parse(row['completed_on'] as String),
      detail: '${row['name']} completed',
    );
  }

  @override
  Duration get duration => until.difference(occurred);

  DateTime get until => ended ?? DateTime.now();

  @override
  String get description => detail ?? actionType.description;

  @override
  IconData get icon => actionType.icon;

  @override
  String get label => actionType.label;
}
