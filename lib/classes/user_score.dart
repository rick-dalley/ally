import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

enum UserScore { dissatisfied, extremelyDissatisfied, satisfied, veryDissatisfied }

extension UserScoreIcon on UserScore {
  IconData get icon {
    switch (this) {
      case UserScore.satisfied:
        return Symbols.sentiment_satisfied;
      case UserScore.dissatisfied:
        return Symbols.sentiment_dissatisfied;
      case UserScore.veryDissatisfied:
        return Symbols.sentiment_very_dissatisfied;
      case UserScore.extremelyDissatisfied:
        return Symbols.sentiment_extremely_dissatisfied;
    }
  }
}
