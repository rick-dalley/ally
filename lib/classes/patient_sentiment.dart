import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum Sentiment { happy, content, neutral, dissatisfied, sad, stressed }

extension SentimentColor on Sentiment {
  Color get color {
    switch (this) {
      case Sentiment.happy:
        return Color(0xFF0EBA00);
      case Sentiment.content:
        return Colors.blue;
      case Sentiment.neutral:
        return Colors.blueGrey;
      case Sentiment.dissatisfied:
        return Colors.purpleAccent;
      case Sentiment.sad:
        return Colors.orange;
      case Sentiment.stressed:
        return Colors.red.shade900;
    }
  }
}

extension SentimentDescription on Sentiment {
  String get description {
    switch (this) {
      case Sentiment.happy:
        return "Thriving: High energy, positive outlook, fully engaged.";
      case Sentiment.content:
        return "Stable: At ease, no discomfort, functioning well.";
      case Sentiment.neutral:
        return "Baseline: Neither distressed nor particularly uplifted.";
      case Sentiment.dissatisfied:
        return "Mild Distress: Persistent discomfort or minor anxiety.";
      case Sentiment.sad:
        return "Low Mood: Withdrawn, lethargic, or lacking motivation.";
      case Sentiment.stressed:
        return "Acute Distress: High anxiety, overwhelmed, requires attention.";
    }
  }
}

enum TextSentiment { noPain, worstPainEver }

class PatientSentiment {
  final IconData iconData;
  final double diameter;
  final Color color;

  const PatientSentiment({required this.iconData, required this.diameter, required this.color});

  Icon getIcon() {
    return Icon(iconData, size: diameter, color: color);
  }
}

final Map<Sentiment, List<int>> sentimentToPainMap = {
  Sentiment.happy: [0],
  Sentiment.content: [1, 2],
  Sentiment.neutral: [3, 4],
  Sentiment.dissatisfied: [5, 6],
  Sentiment.sad: [7, 8],
  Sentiment.stressed: [9, 10],
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

Map<Sentiment, PatientSentiment> patientSentiments = {
  Sentiment.happy: PatientSentiment(iconData: Symbols.sentiment_calm, color: Sentiment.happy.color, diameter: 32),
  Sentiment.content: PatientSentiment(
    iconData: Symbols.sentiment_content,
    color: Sentiment.content.color,
    diameter: 32,
  ),
  Sentiment.neutral: PatientSentiment(
    iconData: Symbols.sentiment_neutral,
    color: Sentiment.neutral.color,
    diameter: 32,
  ),
  Sentiment.dissatisfied: PatientSentiment(
    iconData: Symbols.sentiment_dissatisfied,
    color: Sentiment.dissatisfied.color,
    diameter: 32,
  ),
  Sentiment.sad: PatientSentiment(iconData: Symbols.sentiment_sad, color: Sentiment.sad.color, diameter: 32),
  Sentiment.stressed: PatientSentiment(
    iconData: Symbols.sentiment_stressed,
    color: Sentiment.stressed.color,
    diameter: 32,
  ),
};

Map<TextSentiment, String> dvprs = {TextSentiment.noPain: "", TextSentiment.worstPainEver: "worst pain ever"};
