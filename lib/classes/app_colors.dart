import 'dart:ui';

class AppColors {
  AppColors._(); // Private constructor prevents instantiation

  // Base colors
  static const Color energeticPurple = Color(0xFF3A1772);
  static const Color electricRose = Color(0xFFD741A7);
  static const Color darkMustard = Color(0xFFDEA54B);
  static const Color neonBlue = Color(0xFF2323FF);
  static const Color greyDepth = Color(0xFF818585);

  // Grouped Shades
  static const EnergeticPurple purple = EnergeticPurple._();
  static const ElectricRose rose = ElectricRose._();
  static const DarkMustard mustard = DarkMustard._();
  static const OceanBlue blue = OceanBlue._();
  static const GreyDepth grey = GreyDepth._();
}

class EnergeticPurple {
  const EnergeticPurple._();
  final List<Color> all = const [
    Color(0xFFFFCCFF),
    Color(0xFFEDBBFF),
    Color(0xFFBEBFF7),
    Color(0xFF9165C9),
    Color(0xFF653D9D),
    Color(0xFF3A1772),
    Color(0xFF1E0059),
  ];
  Color operator [](int index) => all[index];
}

class ElectricRose {
  const ElectricRose._();
  final List<Color> all = const [
    Color(0xFFFF09FF),
    Color(0xFFE650B5),
    Color(0xFFD43EA4),
    Color(0xFFD741A7),
    Color(0xFFBB1ABB),
    Color(0xFF990070),
    Color(0xFF7A0056),
  ];
  Color operator [](int index) => all[index];
}

class DarkMustard {
  const DarkMustard._();
  final List<Color> all = const [
    Color(0xFFfce9ca),
    Color(0xFFf7d7a6),
    Color(0xFFfacc87),
    Color(0xFFDEA54B),
    Color(0xFFb48026),
    Color(0xFF8a5c00),
    Color(0xFF633b00),
  ];
  Color operator [](int index) => all[index];
}

class OceanBlue {
  const OceanBlue._();
  final List<Color> all = const [
    Color(0xFF7979FF),
    Color(0xFF6464FF),
    Color(0xFF4E4EFF),
    Color(0xFF3939FF),
    Color(0xFF2323FF),
    Color(0xFF0303FF),
    Color(0xFF0000E2),
  ];
  Color operator [](int index) => all[index];
}

class GreyDepth {
  const GreyDepth._();
  final List<Color> all = const [
    Color(0xFFFFFFFF),
    Color(0xFFF1F5F5),
    Color(0xFFEEF1F1),
    Color(0xFFCCD2D2),
    Color(0xFFA6ABAB),
    Color(0xFF818585),
    Color(0xFF5E6161),
    Color(0xFF3d3F3F),
    Color(0xFF1F2020),
  ];
  Color operator [](int index) => all[index];
}
