// Anything with a position in time — the shared contract a future real timeline
// (currently mock data, see patientActions) would plot against. A logged symptom is
// Temporal (it happened, or is expected, at a point in time) but not every Temporal
// thing is Schedulable — you don't pick in advance when pain starts.
abstract interface class Temporal {
  // The anchor point in time this occupies: when it happened, or when it's
  // expected/targeted to happen.
  DateTime get occursAt;
}
