import 'patient_pain.dart';

// A short, generic list rather than a full symptom taxonomy — this exists purely to
// let a "Sick" mood tap say a little more than the sentiment alone, not to replace the
// real Symptoms feature (body-diagram markers). Order is display order.
const List<String> sicknessSymptomChips = [
  'Nauseous',
  'Chills',
  'Fever',
  'Achy',
  'Sore Throat',
  'Cough',
  'Congestion',
  'Fatigue',
  'Diarrhea',
  'Vomiting',
];

// One "I'm sick" episode, from the moment it's reported (via the Sick mood tap) until
// either the patient says they're better or it's dismissed. Deliberately separate from
// `BodyMarker` — a sickness has no body-diagram location, and its recheck cadence is
// daily rather than every 3 days (see SicknessRecheckReminder).
class SicknessEpisode {
  final String id;
  final String patientUuid;
  final List<String> symptoms;
  final DetailedPainLevel? severity;
  final DateTime startedAt;
  final DateTime? lastCheckedAt;
  final DateTime? resolvedAt;
  final bool seekCareDismissed;

  const SicknessEpisode({
    required this.id,
    required this.patientUuid,
    required this.symptoms,
    this.severity,
    required this.startedAt,
    this.lastCheckedAt,
    this.resolvedAt,
    this.seekCareDismissed = false,
  });

  factory SicknessEpisode.fromRow(Map<String, dynamic> row) {
    final String? symptomsText = row['symptoms'] as String?;
    final int? severityIndex = row['severity'] as int?;
    return SicknessEpisode(
      id: row['id'] as String,
      patientUuid: row['patient_uuid'] as String,
      symptoms: (symptomsText == null || symptomsText.isEmpty)
          ? const []
          : symptomsText.split(',').where((s) => s.isNotEmpty).toList(),
      severity: severityIndex != null ? DetailedPainLevel.values[severityIndex] : null,
      startedAt: DateTime.parse(row['started_at'] as String),
      lastCheckedAt: row['last_checked_at'] != null ? DateTime.tryParse(row['last_checked_at'] as String) : null,
      resolvedAt: row['resolved_at'] != null ? DateTime.tryParse(row['resolved_at'] as String) : null,
      seekCareDismissed: (row['seek_care_dismissed'] as int? ?? 0) == 1,
    );
  }

  // Whether this episode already qualifies for the "seek treatment?" escalation ask —
  // either the patient's severity has gotten worse than it was on the last reading, or
  // it's simply gone on for more than 3 days. previousSeverity is whatever the episode
  // carried *before* the caller applies a new reading, so pass the pre-update value.
  static bool escalates({
    required DateTime startedAt,
    required DetailedPainLevel? previousSeverity,
    required DetailedPainLevel newSeverity,
  }) {
    final bool worsened = previousSeverity != null && newSeverity.index > previousSeverity.index;
    final bool tooLong = DateTime.now().difference(startedAt) > const Duration(days: 3);
    return worsened || tooLong;
  }
}
