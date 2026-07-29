import 'date_time_utilities.dart';

class CompletedQuestionnaire {
  final bool completed;
  final DateTime? when;

  const CompletedQuestionnaire({required this.completed, required this.when});

  factory CompletedQuestionnaire.fromJson(Map<String, dynamic> item) {
    bool isComplete = (item['total'] ?? 0) > 0;

    String? whenCompletedRaw = isComplete ? item['last_modified'] : null;
    DateTime? whenComplete = whenCompletedRaw != null ? DTUtilities.sqliteToDart(whenCompletedRaw) : null;

    return CompletedQuestionnaire(completed: isComplete, when: whenComplete);
  }
}
