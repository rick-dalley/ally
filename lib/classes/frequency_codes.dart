import 'listable.dart';

enum FrequencyCodes implements Listable {
  quaqueDie,
  bisInDie,
  anteCibum,
  postCibum,
  proReNata,
  quaqueAnteMeridiem,
  quaquePostMeridiem,
  quaqueHoraSomni,
  quaterInDie,
  terInDie;

  String get latin {
    switch (this) {
      case quaqueDie:
        return "Quaque die";
      case bisInDie:
        return "Bis in die";
      case terInDie:
        return "Ter in die";
      case quaterInDie:
        return "Quater in die";
      case quaqueHoraSomni:
        return "Quaque hora somni";
      case quaqueAnteMeridiem:
        return "Quaque ante meridiem";
      case quaquePostMeridiem:
        return "Quaque post meridiem";
      case proReNata:
        return "Pro re nata";
      case anteCibum:
        return "Ante cibum";
      case postCibum:
        return "Post cibum";
    }
  }

  @override
  String get description {
    switch (this) {
      case quaqueDie:
        return "Once every 24 hours";
      case bisInDie:
        return "Once every 12 hours";
      case terInDie:
        return "Once every 8 hours";
      case quaterInDie:
        return "Once every 6 hours";
      case FrequencyCodes.anteCibum:
        return "Before meals, as directed";
      case FrequencyCodes.postCibum:
        return "After meals, as directed";
      case FrequencyCodes.proReNata:
        return "As you need";
      case FrequencyCodes.quaqueAnteMeridiem:
        return "Once each morning";
      case FrequencyCodes.quaquePostMeridiem:
        return "Once each evening ";
      case FrequencyCodes.quaqueHoraSomni:
        return "Once each evening before going to bed";
    }
  }

  @override
  String get label {
    switch (this) {
      case quaqueDie:
        return "Once a day";
      case bisInDie:
        return "Twice a day";
      case terInDie:
        return "Three times a day";
      case quaterInDie:
        return "Four times a day";
      case quaqueHoraSomni:
        return "Every night at bedtime";
      case quaqueAnteMeridiem:
        return "Every morning";
      case quaquePostMeridiem:
        return "Every evening";
      case proReNata:
        return "As needed";
      case anteCibum:
        return "Before meals";
      case postCibum:
        return "After meals";
    }
  }

  String get code {
    switch (this) {
      case quaqueDie:
        return "QD";
      case bisInDie:
        return "BID";
      case terInDie:
        return "TID";
      case quaterInDie:
        return "QID";
      case quaqueHoraSomni:
        return "QHS";
      case quaqueAnteMeridiem:
        return "QAM";
      case quaquePostMeridiem:
        return "QPM";
      case proReNata:
        return "PRN";
      case anteCibum:
        return "AC";
      case postCibum:
        return "PC";
    }
  }
}
