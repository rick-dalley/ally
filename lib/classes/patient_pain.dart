import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PainLevel { none, mild, distracting, limiting, incapacitating, severe }

extension PainLevelColor on PainLevel {
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
}

extension PainDescription on PainLevel {
  String get description {
    switch (this) {
      case PainLevel.none:
        return "Thriving: High energy, positive outlook, fully engaged.";
      case PainLevel.mild:
        return "Stable: At ease, no discomfort, functioning well.";
      case PainLevel.distracting:
        return "Baseline: Neither distressed nor particularly uplifted.";
      case PainLevel.limiting:
        return "Mild Distress: Persistent discomfort or minor anxiety.";
      case PainLevel.incapacitating:
        return "Low Mood: Withdrawn, lethargic, or lacking motivation.";
      case PainLevel.severe:
        return "Acute Distress: High anxiety, overwhelmed, requires attention.";
    }
  }
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

Map<PainLevel, PatientPain> pains = {
  PainLevel.none: PatientPain(iconData: Symbols.sentiment_calm, color: PainLevel.none.color, diameter: 32),
  PainLevel.mild: PatientPain(iconData: Symbols.sentiment_content, color: PainLevel.mild.color, diameter: 32),
  PainLevel.distracting: PatientPain(
    iconData: Symbols.sentiment_neutral,
    color: PainLevel.distracting.color,
    diameter: 32,
  ),
  PainLevel.limiting: PatientPain(
    iconData: Symbols.sentiment_dissatisfied,
    color: PainLevel.limiting.color,
    diameter: 32,
  ),
  PainLevel.incapacitating: PatientPain(
    iconData: Symbols.sentiment_sad,
    color: PainLevel.incapacitating.color,
    diameter: 32,
  ),
  PainLevel.severe: PatientPain(iconData: Symbols.sentiment_stressed, color: PainLevel.severe.color, diameter: 32),
};

Map<TextPain, String> painScaleDescriptionMap = {TextPain.noPain: "", TextPain.worstPainEver: "worst pain ever"};
