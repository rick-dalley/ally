enum AboType { a, b, ab, o }

extension ABOTypeLabel on AboType {
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

enum RhFactor { positive, negative }

extension RHFactorSmallLabel on RhFactor {
  String get symbol {
    switch (this) {
      case RhFactor.positive:
        return "+";
      case RhFactor.negative:
        return "-";
    }
  }
}

extension RHFactorLabel on RhFactor {
  String get label {
    switch (this) {
      case RhFactor.positive:
        return "positive";
      case RhFactor.negative:
        return "negative";
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
