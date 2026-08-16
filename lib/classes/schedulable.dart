import 'temporal.dart';

// Something whose occurrence can be predicted or targeted in advance — narrower than
// Temporal (every Schedulable thing is Temporal, but not vice versa: an appointment is
// both, a pain marker is only Temporal). Remindable concepts are inherently Schedulable
// — nextReminder/cadence already are this contract, just not declared as such — but
// existing Remindable classes aren't retrofitted onto this yet; only new code (starting
// with TestReminder) is built against it directly, to avoid a drive-by mass refactor.
abstract interface class Schedulable implements Temporal {
  // Null = one-time/unpredictable recurrence; otherwise roughly how often it repeats.
  Duration? get cadence;
}
