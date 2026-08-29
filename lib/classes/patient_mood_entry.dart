import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/interfaces/carbon_timeline_types.dart';
import 'package:carbon_ui/interfaces/plottable.dart';

import 'patient_sentiment.dart';
import 'temporal.dart';

// "5 days from the start of app usage" — the mood-tracking intro dialog's promise
// (medical_profile_screen.dart) and the timeline's mood-trend lane (timeline_scroller_
// page.dart) both gate on this; one constant so they can't drift apart.
const Duration moodTrendEligibilityThreshold = Duration(days: 5);

// One open-ended period of a patient's self-reported mood — new code, so it's built
// directly against Temporal (occursAt = when this mood period began) rather than
// retrofitting anything existing, ready for the eventual patient diary/timeline to
// read directly. Also Plottable — CarbonTimelineScroller's mood-trend lane strings a
// sorted list of these together directly, one color-change per entry.
class PatientMoodEntry implements Temporal, Plottable {
  final int? id;
  final Sentiment mood;
  final String? reason;
  final DateTime startDate;
  final DateTime? endDate;

  const PatientMoodEntry({this.id, required this.mood, this.reason, required this.startDate, this.endDate});

  @override
  DateTime get occursAt => startDate;

  @override
  DateTime get date => startDate;

  @override
  Color get color => mood.color;

  @override
  IconData? get icon => mood.icon;

  @override
  String? get text => null;

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

// Wraps a patient's mood history as one pickable timeline lane — competes for one of
// CarbonTimelineScroller's "up to 3" slots exactly like a medication course or
// condition span, but paints as the multi-segment trend bar since it also implements
// CarbonTimelineTrend. The caller (timeline_scroller_page.dart) only constructs this
// once moodTrendEligibilityThreshold has passed — before that, it simply doesn't add
// this to availableSpans, so "Mood" doesn't appear in the picker at all yet.
class MoodTrendSpan implements CarbonTimelineTrend {
  final List<PatientMoodEntry> entries; // sorted ascending by date

  const MoodTrendSpan(this.entries);

  @override
  String get sourceId => 'mood-trend';

  @override
  String get label => 'Mood';

  @override
  String get categoryLabel => 'Mood';

  @override
  IconData? get icon => Symbols.mood_sharp;

  @override
  DateTime get startDate => entries.first.startDate;

  @override
  DateTime get endDate => entries.last.endDate ?? DateTime.now();

  @override
  bool get isOngoing => entries.last.endDate == null;

  @override
  List<Plottable> get readings => entries;
}
