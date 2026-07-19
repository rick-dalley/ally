import 'listable.dart';

enum AboType implements Listable {
  a,
  b,
  ab,
  o;

  @override
  String get description {
    switch (this) {
      case AboType.a:
        return "Type A";
      case AboType.b:
        return "Type B";
      case AboType.ab:
        return "Type AB";
      case AboType.o:
        return "Type O";
    }
  }

  @override
  String get label {
    switch (this) {
      case AboType.a:
        return "A";
      case AboType.b:
        return "B";
      case AboType.ab:
        return "AB";
      case AboType.o:
        return "O";
    }
  }
}

enum RhFactor implements Listable {
  positive,
  negative;

  String get symbol {
    switch (this) {
      case RhFactor.positive:
        return "+";
      case RhFactor.negative:
        return "-";
    }
  }

  @override
  String get label {
    switch (this) {
      case RhFactor.positive:
        return "positive";
      case RhFactor.negative:
        return "negative";
    }
  }

  @override
  String get description {
    switch (this) {
      case RhFactor.positive:
        return "RH Positive";
      case RhFactor.negative:
        return "RH Negative";
    }
  }
}

class BloodType {
  final AboType abo;
  final RhFactor rh;

  const BloodType({required this.abo, required this.rh});

  // Factory to parse strings safely
  factory BloodType.fromString(String aboStr, String rhStr) {
    final abo = AboType.values.firstWhere(
      (e) => e.name.toUpperCase() == aboStr.toUpperCase(),
      orElse: () => throw ArgumentError("Invalid ABO type: $aboStr"),
    );

    final rh = (rhStr == '+')
        ? RhFactor.positive
        : (rhStr == '-')
        ? RhFactor.negative
        : throw ArgumentError("Invalid Rh factor: $rhStr");

    return BloodType(abo: abo, rh: rh);
  }

  String get label => "${abo.label}${rh.symbol}";
}
