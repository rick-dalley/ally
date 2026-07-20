import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._(); // Private constructor prevents instantiation

  // Base colors
  static const Color peacockBlue = Color(0xFF096C6C);
  static const Color foamGreen = Color(0xFF0DA673);
  static const Color emeraldGreen = Color(0xFF0B8531);
  static const Color oceanBlue = Color(0xFF0D709E);
  static const Color greyDepth = Color(0xFF818585);

  // Grouped Shades
  static const PeacockBlue peacock = PeacockBlue._();
  static const PaleGreen foam = PaleGreen._();
  static const EmeraldGreen emerald = EmeraldGreen._();
  static const OceanBlue ocean = OceanBlue._();
  static const GreyDepth grey = GreyDepth._();
}

class PeacockBlue {
  const PeacockBlue._();
  final List<Color> all = const [
    Color(0xFFafffff),
    Color(0xFF20e8e8),
    Color(0xFF18bdbd),
    Color(0xFF109393),
    Color(0xFF096c6c),
    Color(0xFF044747),
    Color(0xFF012525),
  ];
  Color operator [](int index) => all[index];
}

class PaleGreen {
  const PaleGreen._();
  final List<Color> all = const [
    Color(0xFF1afeb2),
    Color(0xFF13d192),
    Color(0xFF0da673),
    Color(0xFF077d56),
    Color(0xFF03563a),
    Color(0xFF013220),
    Color(0xFF00150b),
  ];
  Color operator [](int index) => all[index];
}

class EmeraldGreen {
  const EmeraldGreen._();
  final List<Color> all = const [
    Color(0xFF89ff9d),
    Color(0xFF1adb56),
    Color(0xFF12af43),
    Color(0xFF0b8531),
    Color(0xFF055d20),
    Color(0xFF023910),
    Color(0xFF001704),
  ];
  Color operator [](int index) => all[index];
}

class OceanBlue {
  const OceanBlue._();
  final List<Color> all = const [
    Color(0xFFBDDFFE),
    Color(0xFF53BDFD),
    Color(0xFF1596D2),
    Color(0xFF0d709E),
    Color(0xFF064C6D),
    Color(0xFF022B3F),
    Color(0xFF01131F),
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

class AppTheme {
  static Color carbonWhite = Color(0xFFFFFFFF);
  static Color carbonPrimary = AppColors.oceanBlue;
  static Color carbonRed = Color(0xFFFF1010);
  static Color carbonGrey = AppColors.grey.all[5];
  static Color carbonFieldBorder = AppColors.grey.all[4];
  static Color carbonFieldColor = AppColors.grey.all[2];
  static Color carbonFieldBackgroundColor = AppColors.grey.all[2];
  static Color carbonSeparator = AppColors.grey.all[3];
  static Color carbonLabelFontColor = AppColors.grey.all[5];
  static Color carbonFieldFontColor = AppColors.grey.all[6];
  static Color carbonHeaderFontColor = AppColors.grey.all[6];
  static Color carbonPlaceHolderFontColor = AppColors.grey.all[4];
  static Color carbonModalColor = AppColors.grey.all[1];
  static Color carbonScaffoldColor = carbonWhite.withValues(alpha: 0.2);
  // face color
  static Color carbonButtonPrimaryColor = carbonPrimary;
  static Color carbonButtonSecondaryColor = carbonGrey;
  static Color carbonButtonTertiaryColor = carbonWhite;
  static Color carbonButtonGhostColor = carbonWhite;
  static Color carbonButtonDangerColor = carbonRed;

  //border color
  static Color carbonButtonBorderPrimaryColor = carbonPrimary;
  static Color carbonButtonBorderSecondaryColor = carbonGrey;
  static Color carbonButtonBorderTertiaryColor = carbonPrimary;
  static Color carbonButtonBorderGhostColor = carbonWhite;
  static Color carbonButtonBorderDangerColor = carbonRed;

  //font color
  static Color carbonButtonPrimaryFontColor = carbonWhite;
  static Color carbonButtonSecondaryFontColor = carbonWhite;
  static Color carbonButtonTertiaryFontColor = carbonPrimary;
  static Color carbonButtonGhostFontColor = carbonPrimary;
  static Color carbonButtonDangerFontColor = carbonWhite;

  static TextStyle carbonHeadingTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonLabelFontColor,
  );

  static TextStyle carbonPrimaryButtonTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: AppColors.grey.all[0],
  );
  static TextStyle carbonGhostButtonTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonLabelFontColor,
  );
  static TextStyle carbonExpressiveTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonHeaderFontColor,
  );
  static TextStyle carbonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: carbonLabelFontColor,
  );

  static TextStyle carbonTinyTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    color: carbonLabelFontColor,
  );

  static TextStyle carbonTinyTextStyleOnPrimary = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    color: AppColors.grey.all[0],
  );

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
  static final Color surfaceColor = AppColors.grey.all[0];
  static final Color defaultFontColor = AppColors.grey.all[4];
  static final Color defaultInverseFontColor = surfaceColor;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inclusiveSans().fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.grey.all[1],
      textTheme: GoogleFonts.inclusiveSansTextTheme(),
      colorScheme: ColorScheme.light(
        primary: AppColors.peacockBlue,
        secondary: AppColors.foamGreen,
        surface: AppColors.grey.all[0],
      ),

      // AppBar styling for Light Mode (Clean & Professional)
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: defaultFontColor, fontSize: 20, fontWeight: FontWeight.w400),
        iconTheme: IconThemeData(color: carbonButtonPrimaryColor),
      ),

      // FAB remains consistent but pops against the white
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: carbonButtonPrimaryColor,
        foregroundColor: carbonButtonPrimaryFontColor,
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: carbonButtonPrimaryColor,
          foregroundColor: carbonButtonPrimaryFontColor,
          minimumSize: const Size.fromHeight(56), // Standardized height for easy hit-targets
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 1.1),
          elevation: 2, // Subtle lift to distinguish from the background
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: AppColors.grey.all[0],
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
          borderSide: BorderSide(color: carbonFieldBorder),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.greyDepth,
      cardColor: carbonGrey,

      colorScheme: ColorScheme.dark(
        primary: AppColors.peacockBlue,
        secondary: AppColors.foamGreen,
        surface: AppColors.grey[5],
      ),

      // FAB Styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.peacockBlue,
        foregroundColor: AppColors.grey.all[0],
      ),

      // AppBar Styling
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.greyDepth,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: AppColors.grey.all[0], fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey.all[0].withAlpha(8),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.peacockBlue, width: 2)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.grey.all[0])),
      ),
    );
  }
}
