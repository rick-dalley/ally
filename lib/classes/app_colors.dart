import 'dart:ui';

// energeticPurple/electricRose/darkMustard/neonBlue and their shade classes were
// removed 2026-08-14 — none of them are Carbon colors (see carbon_color_constants.dart
// for the real IBM-sourced palette) and none had any remaining call sites once mustard
// was swept out. grey/greyDepth are the only pieces still actually referenced
// (app_theme.dart's core scaffolding), kept as-is rather than migrated blind.
class AppColors {
  AppColors._(); // Private constructor prevents instantiation

  static const Color greyDepth = Color(0xFF818585);

  static const GreyDepth grey = GreyDepth._();
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
