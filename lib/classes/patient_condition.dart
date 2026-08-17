import 'package:carbon_ui/interfaces/listable.dart';

class ConditionReference {
  final int id;
  final String name;
  final String category;

  const ConditionReference({
    required this.id,
    required this.name,
    required this.category,
  });

  // Map a database row map directly into our object model
  factory ConditionReference.fromMap(Map<String, dynamic> map) {
    return ConditionReference(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
    );
  }
}

// Replaces the old Active/Historical boolean — a one-off event (a stroke) and a
// relapsing-remitting condition (eczema) both end up "not currently active," but they
// aren't the same thing, and a patient filling in their history knows the difference.
enum ConditionStatus {
  active,
  inRemission,
  recovered;

  String get label {
    switch (this) {
      case ConditionStatus.active:
        return "Active";
      case ConditionStatus.inRemission:
        return "In Remission";
      case ConditionStatus.recovered:
        return "Recovered";
    }
  }
}

// The unit for a patient-entered approximate duration ("about 3 years") — only used
// when the onset date itself isn't known precisely enough to compute a real duration.
enum DurationUnit implements Listable {
  days,
  weeks,
  months,
  years;

  @override
  String get label {
    switch (this) {
      case DurationUnit.days:
        return "Days";
      case DurationUnit.weeks:
        return "Weeks";
      case DurationUnit.months:
        return "Months";
      case DurationUnit.years:
        return "Years";
    }
  }

  @override
  String get description => label;
}

class PatientCondition {
  final int? id; // Nullable if not yet inserted into SQLite
  final String patientUuid;
  final int conditionId;
  String name;
  String treatmentNotes;
  ConditionStatus status;
  DateTime? onset;

  // The date the condition went into remission, or the date it was considered
  // recovered — meaning depends on `status`. Deliberately left nullable: a patient may
  // remember *that* they recovered without remembering exactly when.
  DateTime? statusDate;

  // Fallback for when onset isn't known precisely enough to compute a real duration —
  // "I don't remember exactly when, but it was a few years." Only meaningful when
  // `onset` is null; whenever onset is known, duration is computed instead, never
  // entered, so the two can never contradict each other.
  int? durationEstimateValue;
  DurationUnit? durationEstimateUnit;

  // Set once the patient has engaged with the "how are you treating this?" prompt
  // (tapped through to Medications/Tests/Metrics for this condition) — not proof they
  // actually added anything, just that they've been through the flow at least once.
  // Drives the small badge on this condition's chip so they can find their way back.
  DateTime? treatmentReviewedAt;

  DateTime recordedAt;

  PatientCondition({
    this.id,
    required this.patientUuid,
    required this.conditionId,
    required this.name,
    required this.status,
    this.treatmentNotes = "",
    this.onset,
    this.statusDate,
    this.durationEstimateValue,
    this.durationEstimateUnit,
    this.treatmentReviewedAt,
  }) : recordedAt = DateTime.now();

  factory PatientCondition.fromCondition(
    String patientUuid,
    ConditionReference condition,
  ) {
    return PatientCondition(
      patientUuid: patientUuid,
      conditionId: condition.id,
      name: condition.name,
      status: ConditionStatus.active,
      onset: DateTime.now(),
    );
  }

  // Only meaningful once onset is known — this is the single source of truth for
  // duration whenever it's available, so the UI never lets a stored estimate compete
  // with it.
  Duration? get computedDuration =>
      onset != null ? (statusDate ?? DateTime.now()).difference(onset!) : null;

  // Convert an engine database row straight into your clean object layout
  factory PatientCondition.fromMap(Map<String, dynamic> map) {
    return PatientCondition(
      id: map['id'] as int,
      patientUuid: map['patient_uuid'] as String,
      conditionId: map['condition_id'] as int,
      name: map['name'] as String? ?? "",
      treatmentNotes: map['treatment_notes'] as String? ?? "",
      status: ConditionStatus.values[map['status'] as int? ?? 0],
      onset: map['onset'] != null
          ? DateTime.parse(map['onset'].toString())
          : null,
      statusDate: map['status_date'] != null
          ? DateTime.parse(map['status_date'].toString())
          : null,
      durationEstimateValue: map['duration_estimate_value'] as int?,
      durationEstimateUnit: map['duration_estimate_unit'] != null
          ? DurationUnit.values[map['duration_estimate_unit'] as int]
          : null,
      treatmentReviewedAt: map['treatment_reviewed_at'] != null
          ? DateTime.parse(map['treatment_reviewed_at'].toString())
          : null,
    );
  }

  // Format properties into a structured map row payload for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_uuid': patientUuid,
      'condition_id': conditionId,
      'treatment_notes': treatmentNotes,
      'status': status.index,
      'onset': onset?.toIso8601String(),
      'status_date': statusDate?.toIso8601String(),
      'duration_estimate_value': durationEstimateValue,
      'duration_estimate_unit': durationEstimateUnit?.index,
    };
  }
}
