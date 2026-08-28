// One destination a wearable alert notifies — a family member, a neighbor, whoever the
// patient wants dialed/messaged. Deliberately not built on Contactable/Contact (see
// contact.dart): those model a richer address-book entry (emails, socials, multiple
// phone types) for providers/family in the main app, where this is a short, ordered
// list of exactly who to notify in an emergency — closer to the emergency_contact
// field already on Patient than to a full contact record.
class EmergencyTarget {
  final String id;
  final String patientUuid;
  final String name;
  final String phone;
  final String? relation;

  const EmergencyTarget({required this.id, required this.patientUuid, required this.name, required this.phone, this.relation});

  factory EmergencyTarget.fromRow(Map<String, dynamic> row) {
    return EmergencyTarget(
      id: row['id'] as String,
      patientUuid: row['patient_uuid'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      relation: row['relation'] as String?,
    );
  }
}
