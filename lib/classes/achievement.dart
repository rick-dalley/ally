// Deliberately simple, generic table — name, why it was earned, an icon, when, and
// who. Hitting a metric target is the first thing that awards one, but the shape
// doesn't know or care about that; any future achievement type just inserts a row.
class Achievement {
  final int? id;
  final String patientUuid;
  final String name;
  final String? reason;
  // A literal glyph to render (the trophy emoji, for now — "until I can think of
  // something better" was Richard's own framing) rather than a resolved IconData.
  // Storing an emoji character is trivially serializable and renders directly in a
  // Text widget; a real IconData isn't safely serializable across icon-package
  // versions the way a plain string is, so this stays simple on purpose.
  final String? icon;
  final DateTime earnedAt;
  // Null until the patient has actually gone and looked at the Trophy Case — drives
  // the avatar halo (see AchievementBadge), which stops the moment this is set rather
  // than fading on a recency timer.
  final DateTime? acknowledgedAt;

  const Achievement({
    this.id,
    required this.patientUuid,
    required this.name,
    this.reason,
    this.icon,
    required this.earnedAt,
    this.acknowledgedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> row) {
    final dynamic rawDate = row['earned_at'];
    final dynamic rawAcknowledged = row['acknowledged_at'];
    return Achievement(
      id: row['id'] as int?,
      patientUuid: row['patient_uuid'] as String,
      name: row['name'] as String,
      reason: row['reason'] as String?,
      icon: row['icon'] as String?,
      earnedAt: rawDate != null
          ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
          : DateTime.now(),
      acknowledgedAt: rawAcknowledged != null
          ? DateTime.tryParse(rawAcknowledged.toString())
          : null,
    );
  }
}
