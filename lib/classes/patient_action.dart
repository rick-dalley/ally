import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/date_time_utilities.dart';

import 'listable.dart';

abstract interface class Actionable implements Listable {
  IconData get icon;
  late DateTime? started;
  late DateTime? ended;
  Duration get duration;
}

enum PatientActionTypes implements Listable {
  measured,
  dosed,
  exercised,
  changedMood;

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
    }
  }

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
    }
  }
}

class PatientAction implements Actionable {
  final PatientActionTypes actionType;
  @override
  DateTime? started;
  @override
  DateTime? ended;
  PatientAction({required this.actionType, this.ended, this.started});

  @override
  Duration get duration {
    DateTime until = ended ?? DateTime.now();
    Duration difference = until.difference(occurred); // This is the standard way
    return difference;
  }

  DateTime get occurred {
    return started ?? DTUtilities.randomHrsAgo(max: 240);
  }

  DateTime get until {
    return ended ?? DateTime.now();
  }

  @override
  String get description {
    return actionType.description;
  }

  @override
  IconData get icon {
    return actionType.icon;
  }

  @override
  String get label {
    return actionType.label;
  }
}

List<PatientAction> patientActions = [
  PatientAction(actionType: PatientActionTypes.changedMood),
  PatientAction(actionType: PatientActionTypes.dosed),
  PatientAction(actionType: PatientActionTypes.exercised),
  PatientAction(actionType: PatientActionTypes.measured),
];
