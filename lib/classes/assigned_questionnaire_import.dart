import 'dart:convert';

// The receiving half of Progressor's "send a questionnaire" handoff — no shared
// backend, a clinician emails the patient whose body carries an
// ally://assignQuestionnaire?data=... deep link. Key names here must match
// Progressor's SendQuestionnaireScreen exactly — there's no shared package/type
// between the two apps for this payload, same as care_plan_import.dart.
class AssignedQuestionnairePayload {
  final String patientName;
  final String templateId;
  final String providerName;
  final String providerEmail;

  const AssignedQuestionnairePayload({
    required this.patientName,
    required this.templateId,
    required this.providerName,
    required this.providerEmail,
  });

  // Returns null rather than throwing — a malformed or truncated link shouldn't crash
  // the app that just opened it (same reasoning as CarePlanImportPayload).
  static AssignedQuestionnairePayload? tryParse(Uri uri) {
    final String? encoded = uri.queryParameters['data'];
    if (encoded == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(base64Url.decode(encoded))) as Map<String, dynamic>;
      final String? templateId = json['templateId'] as String?;
      final String? providerEmail = json['providerEmail'] as String?;
      if (templateId == null || providerEmail == null) return null;
      return AssignedQuestionnairePayload(
        patientName: json['patientName'] as String? ?? 'Unknown Patient',
        templateId: templateId,
        providerName: json['providerName'] as String? ?? 'your provider',
        providerEmail: providerEmail,
      );
    } catch (_) {
      return null;
    }
  }
}
