import 'package:carbon_ui/interfaces/listable.dart';

// What the patient decided to do about a logged symptom — captured at the moment
// they report it (or update it later) so the record reflects their own stated intent,
// not just severity/type/frequency. Useful to a physician later: "the patient chose to
// wait and see" is a different clinical picture than "the patient never mentioned it."
enum SymptomCarePlan implements Listable {
  ignoreForNow,
  keepCheckingIn,
  phoneForAdvice,
  scheduleAppointment,
  seekImmediateHelp,
  call911;

  @override
  String get label {
    switch (this) {
      case SymptomCarePlan.ignoreForNow:
        return "Ignore it for now, see if it goes away";
      case SymptomCarePlan.keepCheckingIn:
        return "Keep checking in on it";
      case SymptomCarePlan.phoneForAdvice:
        return "Phone a clinic or doctor to see if it should be looked at";
      case SymptomCarePlan.scheduleAppointment:
        return "Schedule an appointment";
      case SymptomCarePlan.seekImmediateHelp:
        return "Seek immediate help";
      case SymptomCarePlan.call911:
        return "Call 911";
    }
  }

  @override
  String get description {
    switch (this) {
      case SymptomCarePlan.ignoreForNow:
        return "No action right now — we'll still ask how it's doing later.";
      case SymptomCarePlan.keepCheckingIn:
        return "We'll check in with you on this from time to time.";
      case SymptomCarePlan.phoneForAdvice:
        return "Get a quick opinion before deciding what to do next.";
      case SymptomCarePlan.scheduleAppointment:
        return "Pick a care team member to reach out to.";
      case SymptomCarePlan.seekImmediateHelp:
        return "Find the nearest walk-in clinic or ER.";
      case SymptomCarePlan.call911:
        return "This is an emergency and needs help right away.";
    }
  }

  // Whether choosing this plan should immediately hand off to a "do something about
  // it" flow (opening care-seeking UI) versus just being a recorded, passive intent.
  bool get requiresImmediateAction =>
      this == SymptomCarePlan.phoneForAdvice ||
      this == SymptomCarePlan.scheduleAppointment ||
      this == SymptomCarePlan.seekImmediateHelp ||
      this == SymptomCarePlan.call911;
}
