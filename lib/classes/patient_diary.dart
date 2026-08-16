import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/widgets.dart' show IconData;

import 'patient_pain.dart';
import 'patient_sentiment.dart';

// One saved diary entry — one per patient per day (enforced by a UNIQUE constraint on
// the table, not just convention). Never created for a day with no text; deleted
// outright if cleared back to empty rather than left as a blank row.
class DiaryEntry {
  final int? id;
  final String entryDate; // "YYYY-MM-DD"
  final String content;

  const DiaryEntry({this.id, required this.entryDate, required this.content});

  factory DiaryEntry.fromRow(Map<String, dynamic> row) {
    return DiaryEntry(id: row['id'] as int?, entryDate: row['entry_date'] as String, content: row['content'] as String);
  }
}

// A single thing that happened on a given day, flattened to a uniform shape purely
// for display — medication doses, appointments, symptoms, mood changes, and test
// completions are all real, differently-shaped domain objects; this exists only so
// the diary's day view can render all five in one list without five separate
// ListView sections.
class DiaryDayEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? time;

  const DiaryDayEvent({required this.icon, required this.title, required this.subtitle, this.time});

  factory DiaryDayEvent.medicationDose(Map<String, dynamic> row) {
    final String status = row['status'] as String? ?? 'taken';
    final DateTime scheduledFor = DateTime.parse(row['scheduled_for'] as String);
    return DiaryDayEvent(
      icon: Symbols.medication,
      title: '${row['medication_name'] ?? 'Medication'}${row['dose'] != null ? ' (${row['dose']})' : ''}',
      subtitle: status == 'taken' ? 'Taken' : status == 'missed' ? 'Missed' : status,
      time: scheduledFor,
    );
  }

  factory DiaryDayEvent.appointment(Map<String, dynamic> row) {
    return DiaryDayEvent(
      icon: Symbols.diversity_4,
      title: 'Appointment with ${row['provider_name'] ?? 'your provider'}',
      subtitle: (row['reason'] as String?) ?? '',
      time: DateTime.parse(row['scheduled_for'] as String),
    );
  }

  factory DiaryDayEvent.symptom(Map<String, dynamic> row) {
    final int? severityIndex = row['severity'] as int?;
    final int? frequencyIndex = row['frequency'] as int?;
    final String severity = severityIndex != null ? DetailedPainLevel.values[severityIndex].label : '';
    final String frequency = frequencyIndex != null ? Frequency.values[frequencyIndex].label : '';
    final String subtitle = [severity, frequency].where((s) => s.isNotEmpty).join(', ');
    return DiaryDayEvent(
      icon: Symbols.symptoms,
      title: (row['zone_name'] as String?) ?? 'Symptom',
      subtitle: subtitle.isNotEmpty ? subtitle : ((row['descriptions'] as String?) ?? ''),
      time: DateTime.fromMillisecondsSinceEpoch((row['recorded'] as int) * 1000),
    );
  }

  factory DiaryDayEvent.mood(Map<String, dynamic> row) {
    final Sentiment mood = Sentiment.values[row['mood'] as int];
    final String? reason = row['reason'] as String?;
    return DiaryDayEvent(
      icon: mood.icon,
      title: 'Mood: ${mood.label}',
      subtitle: (reason != null && reason.isNotEmpty) ? reason : '',
      time: DateTime.tryParse(row['start_date'] as String? ?? ''),
    );
  }

  factory DiaryDayEvent.test(Map<String, dynamic> row) {
    return DiaryDayEvent(
      icon: Symbols.lab_panel,
      title: (row['name'] as String?) ?? 'Test',
      subtitle: 'Completed',
      time: DateTime.parse(row['completed_on'] as String),
    );
  }
}
