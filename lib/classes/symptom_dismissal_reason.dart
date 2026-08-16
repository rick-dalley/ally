import 'listable.dart';

// Why a logged symptom is being removed via the marker modal's X button. Kept
// separate from resolving-via-follow-up ("It's Better" in SymptomFollowUpDialog),
// which doesn't collect a reason — this is a more deliberate removal, not a quick
// check-in answer.
enum SymptomDismissalReason implements Listable {
  createdByMistake,
  painDisappeared,
  takingMedication,
  healed;

  @override
  String get label {
    switch (this) {
      case SymptomDismissalReason.createdByMistake:
        return "Created this by mistake";
      case SymptomDismissalReason.painDisappeared:
        return "The pain has disappeared";
      case SymptomDismissalReason.takingMedication:
        return "I'm taking medication for it";
      case SymptomDismissalReason.healed:
        return "It's healed";
    }
  }

  @override
  String get description => '';
}
