import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/carbon_ui.dart';

import 'patient_action.dart';

// Two render modes for the same underlying idea — a stretch of time worth comparing
// against the dots on the main timeline. `period` shades on/off (a medication, a
// diagnosed condition, a provider relationship); `trend` would fill by value instead
// (a metric's readings over time). Only `period` is populated with real data for now —
// metrics-as-lanes is a deliberate next step, not built this pass, kept as an
// intentional discovery for patients who go looking rather than a headline feature.
enum TimelineSpanType { period, trend }

enum TimelineSpanCategory {
  medication,
  condition,
  provider,
  careOrder,
  example;

  String get label {
    switch (this) {
      case TimelineSpanCategory.medication:
        return "Medications";
      case TimelineSpanCategory.condition:
        return "Conditions";
      case TimelineSpanCategory.provider:
        return "Care Team";
      case TimelineSpanCategory.careOrder:
        return "Care Orders";
      case TimelineSpanCategory.example:
        return "Example";
    }
  }

  // Same icon already established for this concept elsewhere in the app.
  IconData get icon {
    switch (this) {
      case TimelineSpanCategory.medication:
        return Symbols.medication;
      case TimelineSpanCategory.condition:
        return Symbols.diagnosis_sharp;
      case TimelineSpanCategory.provider:
        return Symbols.diversity_4;
      case TimelineSpanCategory.careOrder:
        return Symbols.assignment;
      case TimelineSpanCategory.example:
        return Symbols.auto_awesome;
    }
  }
}

abstract class TimelineSpan {
  String get sourceId; // stable identity for the mix-and-match picker's selection state
  String get label;
  DateTime get startDate;
  DateTime get endDate; // ongoing spans resolve this to DateTime.now()
  TimelineSpanType get type;
  TimelineSpanCategory get category;
  bool get isOngoing;
}

// Deliberately no color on the model — up to three spans render together and need to
// stay visually distinct regardless of which categories the patient actually picks, so
// color is assigned positionally by whatever's rendering the selected set, not baked
// into the span itself (baking it in risks two same-category picks looking identical).
class PeriodSpan implements TimelineSpan, CarbonTimelineSpan {
  // Stable identity for the picker's selection matching — a real row id/uuid when this
  // came from the database, or a fixed literal for example data. Deliberately not
  // relying on label+date matching each other, which would misfire for two real
  // records that happen to share both.
  @override
  final String sourceId;
  @override
  final String label;
  @override
  final DateTime startDate;
  @override
  final TimelineSpanCategory category;
  final DateTime? endDateRaw;

  const PeriodSpan({
    required this.sourceId,
    required this.label,
    required this.startDate,
    this.endDateRaw,
    required this.category,
  });

  factory PeriodSpan.medication(Map<String, dynamic> row) {
    return PeriodSpan(
      sourceId: row['id'] as String,
      label: row['name'] as String,
      startDate: DateTime.parse(row['started_taking'] as String),
      endDateRaw: row['stopped_taking'] != null ? DateTime.parse(row['stopped_taking'] as String) : null,
      category: TimelineSpanCategory.medication,
    );
  }

  factory PeriodSpan.condition(Map<String, dynamic> row) {
    return PeriodSpan(
      sourceId: 'condition:${row['id']}',
      label: row['name'] as String,
      startDate: DateTime.parse(row['onset'] as String),
      endDateRaw: row['status_date'] != null ? DateTime.parse(row['status_date'] as String) : null,
      category: TimelineSpanCategory.condition,
    );
  }

  factory PeriodSpan.provider(Map<String, dynamic> row) {
    return PeriodSpan(
      sourceId: row['provider_uuid'] as String,
      label: '${row['first_name']} ${row['last_name']}',
      startDate: DateTime.parse(row['started_seeing'] as String),
      endDateRaw: row['stopped_seeing'] != null ? DateTime.parse(row['stopped_seeing'] as String) : null,
      category: TimelineSpanCategory.provider,
    );
  }

  factory PeriodSpan.careOrder(Map<String, dynamic> row) {
    return PeriodSpan(
      sourceId: row['id'] as String,
      label: row['label'] as String,
      startDate: DateTime.parse(row['imported_at'] as String),
      endDateRaw: row['discontinued_at'] != null ? DateTime.parse(row['discontinued_at'] as String) : null,
      category: TimelineSpanCategory.careOrder,
    );
  }

  @override
  TimelineSpanType get type => TimelineSpanType.period;
  @override
  DateTime get endDate => endDateRaw ?? DateTime.now();
  @override
  bool get isOngoing => endDateRaw == null;

  @override
  String get categoryLabel => category.label;
  @override
  IconData? get icon => category.icon;
}

// Fixed, computed once — never regenerated per frame or per scroll, unlike the widget's
// old mock data (PatientAction.occurred used to fall back to a random timestamp on
// every read, which is exactly why it "changed every time you look at the screen").
// Every label is prefixed "Example:" as a second, redundant safeguard beyond the
// banner the screen shows while this is active — even if a patient scrolls past the
// banner, nothing here can be mistaken for their own real history.
class TimelineExampleData {
  final List<PatientAction> actions;
  final List<PeriodSpan> spans;
  final DateTime startTime;
  final DateTime endTime;

  const TimelineExampleData({required this.actions, required this.spans, required this.startTime, required this.endTime});

  factory TimelineExampleData.build() {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(const Duration(days: 180));
    DateTime at(int daysAgo) => now.subtract(Duration(days: daysAgo));

    final List<PeriodSpan> spans = [
      PeriodSpan(
        sourceId: "example:bp-medication",
        label: "Example: Blood Pressure Medication",
        startDate: at(160),
        endDateRaw: at(90),
        category: TimelineSpanCategory.example,
      ),
      PeriodSpan(
        sourceId: "example:cpap",
        label: "Example: CPAP Therapy",
        startDate: at(120),
        endDateRaw: at(30),
        category: TimelineSpanCategory.example,
      ),
      PeriodSpan(
        sourceId: "example:physical-therapy",
        label: "Example: Physical Therapy",
        startDate: at(45),
        category: TimelineSpanCategory.example,
      ),
    ];

    final List<PatientAction> actions = [
      PatientAction(actionType: PatientActionTypes.dosed, occurred: at(150), detail: "Example: Took blood pressure medication"),
      PatientAction(actionType: PatientActionTypes.changedMood, occurred: at(110), detail: "Example: Mood logged as calm"),
      PatientAction(actionType: PatientActionTypes.measured, occurred: at(80), detail: "Example: Blood pressure reading"),
      PatientAction(actionType: PatientActionTypes.symptomLogged, occurred: at(60), detail: "Example: Mild headache logged"),
      PatientAction(actionType: PatientActionTypes.appointmentAttended, occurred: at(40), detail: "Example: Follow-up appointment"),
      PatientAction(actionType: PatientActionTypes.testCompleted, occurred: at(20), detail: "Example: Bloodwork completed"),
      PatientAction(actionType: PatientActionTypes.measured, occurred: at(5), detail: "Example: Blood pressure reading"),
    ];

    return TimelineExampleData(actions: actions, spans: spans, startTime: start, endTime: now);
  }
}
