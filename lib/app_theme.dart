import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/acuity.dart';

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
    Color(0xFFbddffe),
    Color(0xFF53bdfd),
    Color(0xFF1596d2),
    Color(0xFF0d709e),
    Color(0xFF064c6d),
    Color(0xFF022b3f),
    Color(0xFF01131f),
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
    Color(0xFFa6abab),
    Color(0xFF818585),
    Color(0xFF5e6161),
    Color(0xFF3d3f3f),
    Color(0xFF1f2020),
  ];
  Color operator [](int index) => all[index];
}

class AppTheme {
  static const Color darkSlate = Color(0xFF1E1E1E);
  static const Color clinicalWhite = Color(0xFFF8F9FA);

  static Color cancelButtonBackGround = AppColors.grey.all[3];
  static Color carbonFieldBorder = AppColors.grey.all[4];
  static Color carbonFieldColor = AppColors.grey.all[2];
  static Color carbonFieldBackgroundColor = AppColors.grey.all[2];
  static Color carbonSeparator = AppColors.grey.all[3];
  static Color carbonLabelFontColor = AppColors.grey.all[5];
  static Color carbonFieldFontColor = AppColors.grey.all[6];
  static Color carbonPlaceHolderFontColor = AppColors.grey.all[4];
  static Color carbonErrorFontColor = Color(0xFFDA1E28);

  // Hospital Monitor Vitals Palette
  static const Color vitalsBP = Color(0xFFFFB300);
  static const Color vitalsOxygen = Color(0xFF82B1FF);
  static const Color vitalsPulse = Color(0xFF00E676);
  static const Color vitalsTemp = Color(0xFFFFFFFF);
  static const Color monitorBlack = Color(0xFF000000);

  static const Color resuscitation = Color(0xFF043AC4);
  static const Color emergent = Color(0xFFFC900F);
  static const Color urgent = Color(0xFFFFEA00);
  static const Color lessUrgent = Color(0xFF23C402);
  static const Color nonUrgent = Color(0xFFFFFFFF);

  static Color resuscitationBackground = resuscitation.withAlpha(96);
  static Color emergentBackground = emergent.withAlpha(96);
  static Color urgentBackground = urgent.withAlpha(96);
  static Color lessUrgentBackground = lessUrgent.withAlpha(96);
  static Color nonUrgentBackground = nonUrgent.withAlpha(96);

  static const Map<AcuityLevel, Color> acuityColors = {
    AcuityLevel.resuscitate: resuscitation,
    AcuityLevel.emergent: emergent,
    AcuityLevel.urgent: urgent,
    AcuityLevel.lessUrgent: lessUrgent,
    AcuityLevel.notUrgent: nonUrgent,
  };

  static const Map<AcuityLevel, Color> acuityFontColors = {
    AcuityLevel.resuscitate: resuscitation,
    AcuityLevel.emergent: emergent,
    AcuityLevel.urgent: Color(0xFF000000),
    AcuityLevel.lessUrgent: lessUrgent,
    AcuityLevel.notUrgent: Color(0xFF080808),
  };

  static Map<AcuityLevel, Color> acuityBackgroundColors = {
    AcuityLevel.resuscitate: resuscitationBackground,
    AcuityLevel.emergent: emergentBackground,
    AcuityLevel.urgent: urgentBackground,
    AcuityLevel.lessUrgent: lessUrgentBackground,
    AcuityLevel.notUrgent: nonUrgentBackground,
  };

  static const Map<AcuityLevel, IconData> acuityIcons = {
    AcuityLevel.resuscitate: Icons.emergency,
    AcuityLevel.emergent: Icons.circle_rounded,
    AcuityLevel.urgent: Icons.circle_rounded,
    AcuityLevel.lessUrgent: Icons.circle_rounded,
    AcuityLevel.notUrgent: Icons.circle_rounded,
  };

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
        iconTheme: IconThemeData(color: AppColors.peacockBlue),
      ),

      // FAB remains consistent but pops against the white
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.oceanBlue,
        foregroundColor: defaultInverseFontColor,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.peacockBlue,
          foregroundColor: defaultInverseFontColor,
          minimumSize: const Size.fromHeight(55), // Standardized height for easy hit-targets
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
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
      cardColor: darkSlate,

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

  static Map<String, IconData> eventIcons = {
    "ED_ARRIV": Symbols.check_in_out,
    "ED_AMBUL": Symbols.ambulance,
    "ED_POLIC": Symbols.local_police,
    "ED_INTAK": Symbols.medical_information,
    "ID_ANONY": Symbols.person_off,
    "ID_MERGE": Symbols.person_check,
    "TR_START": Symbols.stethoscope,
    "TR_COMPL": Symbols.stethoscope_check,
    "TR_REASS": Symbols.stethoscope_arrow,
    "DC_LWBS": Symbols.run_circle,
    "ED_ALLOC": Symbols.short_stay,
    "MD_ASSES": Symbols.medical_mask,
    "VT_LOGGD": Symbols.vital_signs,
    "CL_NOTES": Symbols.clinical_notes,
    "ED_RELOC": Symbols.moving_beds,
    "LB_ORDER": Symbols.fluid_balance,
    "LB_DRAWN": Symbols.labs,
    "LB_HEMOL": Symbols.hematology,
    "LB_RESUL": Symbols.lab_profile,
    "IM_ORDER": Symbols.skeleton,
    "IM_START": Symbols.radiology,
    "IM_REJCT": Symbols.radiology, //add an xbadge
    "IM_INTER": Symbols.radiology, //add a magnifying glass
    "MD_ADMIN": Symbols.admin_meds,
    "PR_PERFM": Symbols.procedure,
    "BL_TRANS": Symbols.fluid,
    "MH_DETAIN": Symbols.psychiatry_sharp,
    "RE_START": Symbols.shield_lock,
    "RE_TERMN": Symbols.shield,
    "IS_OLATN": Symbols.safety_divider,
    "PO_POWER": Symbols.balance,
    "SEC_INCI": Symbols.admin_panel_settings,
    "CS_REQU": Symbols.person_add,
    "CS_ARRIV": Symbols.person,
    "CS_DECIS": Symbols.person_check,
    "DP_DECIS": Symbols.arrow_split,
    "WD_REQU": Symbols.contact_support,
    "WD_ALLOC": Symbols.ward,
    "WD_REPOR": Symbols.assignment,
    "ED_BOARD": Symbols.short_stay,
    "ED_DEPAR": Symbols.moving_beds,
    "OR_TRANS": Symbols.surgical,
    "IC_TRANS": Symbols.diversity_1,
    "WD_ARRIV": Symbols.inpatient,
    "DC_INSTR": Symbols.developer_guide,
    "DC_CLEAR": Symbols.door_open,
    "DC_COMPL": Symbols.home,
    "DC_AMA": Symbols.person_cancel,
    "DC_ELOPD": Symbols.luggage,
    "DC_SHEL": Symbols.night_shelter,
    "DC_EXTRN": Symbols.local_police,
    "HSP_TRNS": Symbols.local_hospital,
    "DC_PASTR": Symbols.family_home,
    "PT_DECEAS": Symbols.deceased,
    "DC_CORON": Symbols.deceased,
    "UNKNWN": Symbols.unknown_document,
  };
}
