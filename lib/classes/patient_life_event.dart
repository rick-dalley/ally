import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/interfaces/plottable.dart';

import 'patient_sentiment.dart';
import 'temporal.dart';

// One thing that happened in a patient's life, and how it felt — "piano recital, I
// bombed" / Sad, "they surprised me with lunch" / Happy.
//
// This is deliberately NOT a field on patient_mood. A mood row is an open-ended
// *period* that stays current until something supersedes it; an event is a point in
// time. Hanging the event off the open period would attribute a Friday evening to
// Tuesday's sadness whenever the mood hadn't changed in between. So the sentiment is
// carried here, as a plain Sentiment index, and it stays true no matter what the
// patient taps afterwards.
//
// `mood` is nullable on purpose — "job interview" is worth recording even when the
// patient doesn't want to rate how it felt, and forcing a rating is exactly the kind
// of friction that stops people logging anything at all.
class PatientLifeEvent implements Temporal, Plottable {
  final int? id;
  final String title;
  final String? note;
  final Sentiment? mood;
  final DateTime occurredAt;
  final DateTime createdAt;

  const PatientLifeEvent({
    this.id,
    required this.title,
    this.note,
    this.mood,
    required this.occurredAt,
    required this.createdAt,
  });

  @override
  DateTime get occursAt => occurredAt;

  @override
  DateTime get date => occurredAt;

  // Falls back to the neutral sentiment's color rather than anything of its own — an
  // unrated event still has to paint as *something* on a lane whose whole vocabulary
  // is Sentiment's palette, and inventing a seventh color for "no answer" would read
  // as a mood the patient never chose.
  @override
  Color get color => (mood ?? Sentiment.neutral).color;

  @override
  IconData? get icon => mood?.icon ?? Symbols.event_note;

  @override
  String? get text => title;

  // Written down later than it happened — the diary's retrospective path (adding
  // something to a day you've navigated back to) rather than an in-the-moment
  // check-in. Kept as a derived property instead of a stored flag since the two
  // timestamps already say it.
  bool get isRetrospective => createdAt.difference(occurredAt).inMinutes.abs() > 5;

  factory PatientLifeEvent.fromRow(Map<String, dynamic> row) {
    final int? moodIndex = row['mood'] as int?;
    return PatientLifeEvent(
      id: row['id'] as int?,
      title: row['title'] as String,
      note: row['note'] as String?,
      mood: moodIndex != null ? Sentiment.values[moodIndex] : null,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
