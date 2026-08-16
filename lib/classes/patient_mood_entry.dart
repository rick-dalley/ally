import 'patient_sentiment.dart';
import 'temporal.dart';

// One open-ended period of a patient's self-reported mood — new code, so it's built
// directly against Temporal (occursAt = when this mood period began) rather than
// retrofitting anything existing, ready for the eventual patient diary/timeline to
// read directly.
class PatientMoodEntry implements Temporal {
  final int? id;
  final Sentiment mood;
  final String? reason;
  final DateTime startDate;
  final DateTime? endDate;

  const PatientMoodEntry({this.id, required this.mood, this.reason, required this.startDate, this.endDate});

  @override
  DateTime get occursAt => startDate;

  bool get isCurrent => endDate == null;

  factory PatientMoodEntry.fromRow(Map<String, dynamic> row) {
    return PatientMoodEntry(
      id: row['id'] as int?,
      mood: Sentiment.values[row['mood'] as int],
      reason: row['reason'] as String?,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: row['end_date'] != null ? DateTime.tryParse(row['end_date'] as String) : null,
    );
  }
}
