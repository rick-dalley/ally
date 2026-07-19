import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'flyable.dart';

enum Sentiment implements Flyable {
  angry,
  calm,
  content,
  excited,
  frustrated,
  happy,
  neutral,
  sad,
  stressed,
  worried,
  sick;

  @override
  Color get color {
    return AppColors.greyDepth;
  }

  @override
  Color get onPrimary {
    return AppColors.grey.all[0];
  }

  @override
  IconData get icon {
    switch (this) {
      case Sentiment.angry:
        return Symbols.sentiment_extremely_dissatisfied_sharp;
      case Sentiment.calm:
        return Symbols.sentiment_calm_sharp;
      case Sentiment.content:
        return Symbols.sentiment_content_sharp;
      case Sentiment.excited:
        return Symbols.sentiment_excited_sharp;
      case Sentiment.frustrated:
        return Symbols.sentiment_frustrated_sharp;
      case Sentiment.happy:
        return Symbols.mood_sharp;
      case Sentiment.neutral:
        return Symbols.sentiment_neutral_sharp;
      case Sentiment.sad:
        return Symbols.sentiment_sad_sharp;
      case Sentiment.stressed:
        return Symbols.sentiment_stressed_sharp;
      case Sentiment.worried:
        return Symbols.sentiment_worried_sharp;
      case Sentiment.sick:
        return Symbols.sick_sharp;
    }
  }

  @override
  String get label {
    switch (this) {
      case Sentiment.angry:
        return "Angry";
      case Sentiment.calm:
        return "Calm";
      case Sentiment.content:
        return "Content";
      case Sentiment.excited:
        return "Excited";
      case Sentiment.frustrated:
        return "Frustrated";
      case Sentiment.happy:
        return "Happy";
      case Sentiment.neutral:
        return "Neutral";
      case Sentiment.sad:
        return "Sad";
      case Sentiment.stressed:
        return "Stressed";
      case Sentiment.worried:
        return "Worried";
      case Sentiment.sick:
        return "Sick";
    }
  }

  @override
  String get description {
    switch (this) {
      case Sentiment.happy:
        return "Thriving: High energy, positive outlook, fully engaged.";
      case Sentiment.content:
        return "Stable: At ease, no discomfort, functioning well.";
      case Sentiment.calm:
      case Sentiment.neutral:
        return "Baseline: Neither distressed nor particularly uplifted.";
      case Sentiment.worried:
        return "Mild Distress: Persistent discomfort or minor anxiety.";
      case Sentiment.sad:
        return "Low Mood: Withdrawn, lethargic, or lacking motivation.";
      case Sentiment.stressed:
        return "Acute Distress: High anxiety, overwhelmed, requires attention.";
      case Sentiment.angry:
        return "Angry";
      case Sentiment.excited:
        return "Excited";
      case Sentiment.frustrated:
        return "Frustrated";
      case Sentiment.sick:
        return "Sick";
    }
  }
}
