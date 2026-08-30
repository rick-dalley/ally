import 'dart:convert';

// The sending half of a completed, clinician-requested questionnaire's results —
// mirrors care_plan_import.dart's shape in reverse: no shared backend, this app
// emails the provider whose body carries a progressor://questionnaireResult?data=...
// deep link. Key names here must match Progressor's own receiving payload exactly —
// see that app's questionnaire_result_import.dart.
class QuestionnaireResultPayload {
  static String buildDeepLink({
    required String patientName,
    required String templateId,
    required int score,
    required String summary,
    String? action,
  }) {
    final Map<String, dynamic> payload = {
      'v': 1,
      'patientName': patientName,
      'templateId': templateId,
      'score': score,
      'summary': summary,
      'action': action,
      'answeredAt': DateTime.now().toIso8601String(),
    };
    final String encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return 'progressor://questionnaireResult?data=$encoded';
  }
}
