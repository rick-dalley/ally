import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/classes/archived/carbon_color_constants_old.dart';

import 'classes/app_colors.dart';

class AppTheme {
  // Hospital Monitor Vitals Palette
  static const Color vitalsBP = Color(0xFFFFB300);
  static const Color vitalsOxygen = Color(0xFF82B1FF);
  static const Color vitalsPulse = Color(0xFF00E676);
  static const Color vitalsTemp = Color(0xFFFFFFFF);
  static const Color monitorBlack = Color(0xFF000000);

  // Background colors
  static final Color canvasColor = AppColors.grey.all[1];
  static final Color cardBorder = AppColors.grey.all[3];
  static final Color chipBorder = AppColors.grey.all[3];
  static final Color dividerColor = AppColors.greyDepth;
  static final Color surfaceColor = Colors.white;
  static final Color defaultFontColor = Color(0xFF1F2020);
  static final Color primaryColor = carbonColorPrimary04;
  static final Color onPrimaryColor = Colors.white;
  static final Color secondaryColor = AppColors.grey[5];
  static final Color onSecondaryColor = Colors.white;
  static final Color tertiaryColor = Colors.white;
  static final Color onTertiaryColor = primaryColor;
  static final Color scaffoldBackgroundColor = canvasColor;
  static final Color appBarBackgroundColor = surfaceColor;
  static final Color defaultHintColor = AppColors.grey.all[5];

  static TextStyle defaultTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppTheme.defaultFontColor,
  );
  static TextStyle defaultExpressiveTextStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppTheme.defaultFontColor,
  );

  static TextStyle defaultItalicsTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    fontStyle: FontStyle.italic,
    color: AppTheme.defaultFontColor,
  );

  static TextStyle defaultHeadingStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppTheme.defaultFontColor,
  );

  static TextStyle defaultHintStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppTheme.defaultHintColor,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inclusiveSans().fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.grey.all[1],
      textTheme: GoogleFonts.inclusiveSansTextTheme(),
      colorScheme: ColorScheme.light(
        primary: AppTheme.primaryColor,
        secondary: AppColors.greyDepth,
        surface: surfaceColor,
      ),

      // AppBar styling for Light Mode (Clean & Professional)
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: defaultFontColor, fontSize: 20, fontWeight: FontWeight.w400),
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // FAB remains consistent but pops against the white
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          minimumSize: const Size.fromHeight(56), // Standardized height for easy hit-targets
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 1.1),
          elevation: 2, // Subtle lift to distinguish from the background
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 1.1),
          elevation: 2, // Subtle lift to distinguish from the background
        ),
      ),
      // Text fields that look "Interactive" but clean
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey.all[2],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.greyDepth,
      cardColor: Colors.white,

      colorScheme: ColorScheme.dark(primary: primaryColor, secondary: AppColors.greyDepth, surface: AppColors.grey[5]),

      // FAB Styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
      ),

      // AppBar Styling
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.greyDepth,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: onPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: onPrimaryColor.withAlpha(8),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: onPrimaryColor)),
      ),
    );
  }
}
