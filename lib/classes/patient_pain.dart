import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'flyable.dart';
import 'listable.dart';

enum Frequency implements Flyable {
  cyclical,
  chronic,
  acute;

  @override
  Color get color => AppTheme.carbonLabelFontColor;

  @override
  String get description {
    switch (this) {
      case Frequency.cyclical:
        return "The pain comes and goes";
      case Frequency.chronic:
        return "The pain is nagging and continuous";
      case Frequency.acute:
        return "The pain is strong and intense";
    }
  }

  @override
  IconData get icon {
    switch (this) {
      case Frequency.cyclical:
        return Symbols.cycle;
      case Frequency.chronic:
        return Symbols.all_inclusive;
      case Frequency.acute:
        return Symbols.explosion;
    }
  }

  @override
  String get label {
    switch (this) {
      case Frequency.cyclical:
        return "Cyclical";
      case Frequency.chronic:
        return "Chronic";
      case Frequency.acute:
        return "Acute";
    }
  }

  @override
  Color get onPrimary => AppColors.grey.all[0];
}

enum PainType implements Listable {
  stinging,
  penetrating,
  dull,
  throbbing,
  achy,
  nagging,
  gnawing,
  sharp;

  @override
  // TODO: implement description
  String get description {
    switch (this) {
      case PainType.stinging:
        return "Stinging";
      case PainType.penetrating:
        return "Penetrating";
      case PainType.dull:
        return "Dull";
      case PainType.throbbing:
        return "Throbbing";
      case PainType.achy:
        return "Achy";
      case PainType.nagging:
        return "Nagging";
      case PainType.gnawing:
        return "Gnawing";
      case PainType.sharp:
        return "Sharp";
    }
  }

  @override
  // TODO: implement label
  String get label {
    switch (this) {
      case PainType.stinging:
        return "Stinging";
      case PainType.penetrating:
        return "Penetrating";
      case PainType.dull:
        return "Dull";
      case PainType.throbbing:
        return "Throbbing";
      case PainType.achy:
        return "Achy";
      case PainType.nagging:
        return "Nagging";
      case PainType.gnawing:
        return "Gnawing";
      case PainType.sharp:
        return "Sharp";
    }
  }
}

enum PainLevel implements Flyable {
  none,
  mild,
  distracting,
  limiting,
  incapacitating,
  severe;

  @override
  Color get color {
    switch (this) {
      case PainLevel.none:
        return Color(0xFF0EBA00);
      case PainLevel.mild:
        return Colors.blue;
      case PainLevel.distracting:
        return Colors.blueGrey;
      case PainLevel.limiting:
        return Colors.purpleAccent;
      case PainLevel.incapacitating:
        return Colors.orange;
      case PainLevel.severe:
        return Colors.red.shade900;
    }
  }

  @override
  String get description {
    switch (this) {
      case PainLevel.none:
        return "No pain. I feel normal.";
      case PainLevel.mild:
        return "Noticeable, but I can do daily activities.";
      case PainLevel.distracting:
        return "Distressing/distracting, but can do daily activities.";
      case PainLevel.limiting:
        return "Limiting. Cannot do daily activities.";
      case PainLevel.incapacitating:
        return "Unable to function.";
      case PainLevel.severe:
        return "Severe. As bad as it gets.";
    }
  }

  @override
  IconData get icon {
    switch (this) {
      case PainLevel.none:
        return Symbols.sentiment_calm;
      case PainLevel.mild:
        return Symbols.sentiment_content;
      case PainLevel.distracting:
        return Symbols.sentiment_neutral;
      case PainLevel.limiting:
        return Symbols.sentiment_dissatisfied;
      case PainLevel.incapacitating:
        return Symbols.sentiment_sad;
      case PainLevel.severe:
        return Symbols.sentiment_stressed;
    }
  }

  @override
  String get label {
    switch (this) {
      case PainLevel.none:
        return "None";
      case PainLevel.mild:
        return "Noticeable";
      case PainLevel.distracting:
        return "Distracting";
      case PainLevel.limiting:
        return "Limiting";
      case PainLevel.incapacitating:
        return "Incapacitating";
      case PainLevel.severe:
        return "Unbearable";
    }
  }

  @override
  Color get onPrimary => AppColors.grey.all[0];
}

enum TextPain { noPain, worstPainEver }

class PatientPain {
  final IconData iconData;
  final double diameter;
  final Color color;

  const PatientPain({required this.iconData, required this.diameter, required this.color});

  Icon getIcon() {
    return Icon(iconData, size: diameter, color: color);
  }
}

final Map<PainLevel, List<int>> painLevelToDescription = {
  PainLevel.none: [0],
  PainLevel.mild: [1, 2],
  PainLevel.distracting: [3, 4],
  PainLevel.limiting: [5, 6],
  PainLevel.incapacitating: [7, 8],
  PainLevel.severe: [9, 10],
};

final List<String> disabledVeteransPainScaleDescriptions = [
  "0: No pain. Feels normal.",
  "1: Hardly noticeable.",
  "2: Noticeable/distracting, but can do daily activities.",
  "3: Distressing/distracting, but can do daily activities.",
  "4: Strong, life-interrupting. I need to stop.",
  "5: Strong, life-limiting. Cannot do daily activities.",
  "6: Strong, life-limiting. Struggling to concentrate.",
  "7: Severe, life-limiting. Cannot engage in any activity.",
  "8: Intense, life-limiting. Unable to function.",
  "9: Intense, life-limiting. Bed-bound.",
  "10: As bad as it could be. Nothing else matters.",
];

enum DetailedPainLevel implements Flyable {
  none,
  mild,
  minor,
  distracting,
  moderate,
  moderatelyStrong,
  difficult,
  strong,
  interfering,
  unbearable,
  debilitating;

  @override
  // TODO: implement color
  Color get color {
    switch (this) {
      case DetailedPainLevel.none:
      case DetailedPainLevel.mild:
        return PainLevel.none.color;
      case DetailedPainLevel.minor:
      case DetailedPainLevel.distracting:
        return PainLevel.mild.color;
      case DetailedPainLevel.moderate:
      case DetailedPainLevel.moderatelyStrong:
      case DetailedPainLevel.difficult:
        return PainLevel.distracting.color;
      case DetailedPainLevel.strong:
      case DetailedPainLevel.interfering:
        return PainLevel.limiting.color;
      case DetailedPainLevel.unbearable:
      case DetailedPainLevel.debilitating:
        return PainLevel.severe.color;
    }
  }

  @override
  // TODO: implement description
  String get description {
    switch (this) {
      case DetailedPainLevel.none:
        return "Pain free.";
      case DetailedPainLevel.mild:
        return "Very mild, barely noticeable; you don't think about it most of the time.";
      case DetailedPainLevel.minor:
        return "Minor pain, annoying; may have occasional sharp twinges.";
      case DetailedPainLevel.distracting:
        return "Noticeable and distracting; however, you can adapt and get used to it.";
      case DetailedPainLevel.moderate:
        return "Moderate pain; you can ignore it for periods of time if deeply involved in an activity, but it is still distracting";
      case DetailedPainLevel.moderatelyStrong:
        return "Moderately strong pain; cannot be ignored for more than a few minutes, but you can still work or socialize with effort";
      case DetailedPainLevel.difficult:
        return "Interferes with normal daily activities; you have difficulty concentrating";
      case DetailedPainLevel.strong:
        return "Strong pain; prevents you from doing normal daily activities";
      case DetailedPainLevel.interfering:
        return "Very strong pain; it is hard to do anything at all";
      case DetailedPainLevel.unbearable:
        return "Very hard to tolerate; you cannot carry on a conversation";
      case DetailedPainLevel.debilitating:
        return "Worst pain possible";
    }
  }

  @override
  // TODO: implement icon
  IconData get icon {
    switch (this) {
      case DetailedPainLevel.none:
      case DetailedPainLevel.mild:
        return PainLevel.none.icon;
      case DetailedPainLevel.minor:
      case DetailedPainLevel.distracting:
        return PainLevel.mild.icon;
      case DetailedPainLevel.moderate:
      case DetailedPainLevel.moderatelyStrong:
      case DetailedPainLevel.difficult:
        return PainLevel.distracting.icon;
      case DetailedPainLevel.strong:
      case DetailedPainLevel.interfering:
        return PainLevel.limiting.icon;
      case DetailedPainLevel.unbearable:
      case DetailedPainLevel.debilitating:
        return PainLevel.severe.icon;
    }
  }

  @override
  String get label {
    switch (this) {
      case DetailedPainLevel.none:
        return "None";
      case DetailedPainLevel.mild:
        return "Mild";
      case DetailedPainLevel.minor:
        return "Minor";
      case DetailedPainLevel.distracting:
        return "Distracting";
      case DetailedPainLevel.moderate:
        return "Moderate";
      case DetailedPainLevel.moderatelyStrong:
        return "Moderately Strong";
      case DetailedPainLevel.difficult:
        return "Difficult";
      case DetailedPainLevel.strong:
        return "Strong";
      case DetailedPainLevel.interfering:
        return "interfering";
      case DetailedPainLevel.unbearable:
        return "Unbearable";
      case DetailedPainLevel.debilitating:
        return "Debilitating";
    }
  }

  @override
  Color get onPrimary => AppColors.grey.all[0];
}
