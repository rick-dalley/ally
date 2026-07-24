import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'carbon_color_constants.dart';

enum CarbonSpacing { narrow, medium, wide }

extension CarbonSpacingHeight on CarbonSpacing {
  double get height {
    switch (this) {
      case CarbonSpacing.narrow:
        return 8.0;
      case CarbonSpacing.medium:
        return 16.0;
      case CarbonSpacing.wide:
        return 24.0;
    }
  }
}

extension CarbonSpacingWidth on CarbonSpacing {
  double get width {
    switch (this) {
      case CarbonSpacing.narrow:
        return 8.0;
      case CarbonSpacing.medium:
        return 16.0;
      case CarbonSpacing.wide:
        return 24.0;
    }
  }
}

enum CarbonButtonStyle { danger, ghost, primary, secondary, tertiary }

enum CarbonButtonSize { extraSmall, small, medium, large, largeBold, extraLarge, extraExtraLarge }

extension CarbonButtonSizeHeight on CarbonButtonSize {
  double get height {
    switch (this) {
      case CarbonButtonSize.extraSmall:
        return 32;
      case CarbonButtonSize.small:
        return 40;
      case CarbonButtonSize.medium:
        return 48;
      case CarbonButtonSize.large:
      case CarbonButtonSize.largeBold:
        return 56;
      case CarbonButtonSize.extraLarge:
        return 64;
      case CarbonButtonSize.extraExtraLarge:
        return 72;
    }
  }
}

extension CarbonButtonVerticalPadding on CarbonButtonSize {
  double get verticalPadding {
    switch (this) {
      case CarbonButtonSize.extraSmall:
        return 4;
      case CarbonButtonSize.small:
        return 6;
      case CarbonButtonSize.medium:
        return 8;
      case CarbonButtonSize.large:
        return 12;
      case CarbonButtonSize.largeBold:
        return 10;
      case CarbonButtonSize.extraLarge:
        return 16;
      case CarbonButtonSize.extraExtraLarge:
        return 24;
    }
  }
}

extension CarbonButtonFontSize on CarbonButtonSize {
  double get fontSize {
    switch (this) {
      case CarbonButtonSize.extraSmall:
      case CarbonButtonSize.small:
        return 12;
      case CarbonButtonSize.medium:
        return 14;
      case CarbonButtonSize.large:
        return 18;
      case CarbonButtonSize.largeBold:
      case CarbonButtonSize.extraLarge:
      case CarbonButtonSize.extraExtraLarge:
        return 20;
    }
  }
}

class CarbonTheme {
  static TextStyle carbonHeadingTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonColorTextPrimary,
  );

  static TextStyle carbonPrimaryButtonTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: AppTheme.onPrimaryColor,
  );
  static TextStyle carbonGhostButtonTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonColorButtonGhost,
  );
  static TextStyle? carbonExpressiveTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: AppTheme.primaryColor,
  );

  static TextStyle? carbonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: carbonColorTextPrimary,
  );

  static TextStyle? carbonLabelTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: carbonColorTextSecondary,
  );

  static TextStyle? carbonFieldTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: carbonColorTextPrimary,
  );
  static TextStyle? dangerTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: carbonColorButtonOnDanger,
  );
  static TextStyle? carbonLabelOnPrimary = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: carbonColorTextSecondary,
  );

  static TextStyle? carbonHelperTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: carbonColorTextHelper,
  );

  static TextStyle? carbonHintTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: carbonColorTextHelper,
  );

  static TextStyle? carbonPlaceholderTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: carbonColorTextPlaceholder,
  );
}
