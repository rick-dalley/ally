import 'notifiable.dart';

// A physician's non-medication order, as received via the Progressor discharge
// handoff (see care_plan_import.dart) — physical therapy, observation, restraints, and
// so on. This is the "detail" view of a care_order row (label + directions + the
// wearable-sync toggle); timeline_span.dart's PeriodSpan.careOrder reads the same
// table for the patient's shared timeline, a different, lighter-weight view of it.
class CareOrder implements Notifiable {
  @override
  final String notifiableId;
  final String patientUuid;
  @override
  final String title;
  final String? directions;
  final String? frequency;
  @override
  final bool wearableSyncEnabled;
  final DateTime importedAt;
  final bool isActive;

  const CareOrder({
    required this.notifiableId,
    required this.patientUuid,
    required this.title,
    this.directions,
    this.frequency,
    required this.wearableSyncEnabled,
    required this.importedAt,
    required this.isActive,
  });

  @override
  String get detail => [directions, frequency].where((s) => s != null && s.isNotEmpty).join(' — ');

  factory CareOrder.fromRow(Map<String, dynamic> row) {
    return CareOrder(
      notifiableId: row['id'] as String,
      patientUuid: row['patient_uuid'] as String,
      title: row['label'] as String,
      directions: row['directions'] as String?,
      frequency: row['frequency'] as String?,
      wearableSyncEnabled: (row['wearable_sync'] as int? ?? 0) == 1,
      importedAt: DateTime.parse(row['imported_at'] as String),
      isActive: row['discontinued_at'] == null,
    );
  }
}
