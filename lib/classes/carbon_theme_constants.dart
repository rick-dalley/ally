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

enum CarbonTileStyle { base, clickable, selectable, expandable }

enum CarbonTileFeatureFlags { single, multi, interactive }

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
        return 14;
      case CarbonButtonSize.small:
        return 16;
      case CarbonButtonSize.medium:
        return 18;
      case CarbonButtonSize.large:
      case CarbonButtonSize.largeBold:
      case CarbonButtonSize.extraLarge:
        return 20;
      case CarbonButtonSize.extraExtraLarge:
        return 22;
    }
  }
}

class CarbonTheme {
  static TextStyle carbonHeadingTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.extraExtraLarge.fontSize,
    color: carbonColorTextPrimary,
  );

  static TextStyle carbonPrimaryButtonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.large.fontSize,
    color: AppTheme.onPrimaryColor,
  );

  static TextStyle carbonGhostButtonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.large.fontSize,
    color: carbonColorButtonGhost,
  );

  static TextStyle carbonTertiaryButtonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.large.fontSize,
    color: carbonColorButtonOnTertiary,
  );

  static TextStyle? carbonExpressiveTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.extraExtraLarge.fontSize,
    color: AppTheme.primaryColor,
  );

  static TextStyle? carbonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.medium.fontSize,
    color: carbonColorTextPrimary,
  );

  static TextStyle? carbonLabelTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.small.fontSize,
    color: carbonColorTextSecondary,
  );

  static TextStyle? carbonFieldTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.medium.fontSize,
    color: carbonColorTextPrimary,
  );
  static TextStyle? dangerTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.medium.fontSize,
    color: carbonColorButtonOnDanger,
  );
  static TextStyle? carbonLabelOnPrimary = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.medium.fontSize,
    color: carbonColorTextSecondary,
  );

  static TextStyle? carbonHelperTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.small.fontSize,
    color: carbonColorTextHelper,
  );

  static TextStyle? carbonHintTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.small.fontSize,
    color: carbonColorTextHelper,
  );

  static TextStyle? carbonPlaceholderTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtonSize.medium.fontSize,
    color: carbonColorTextPlaceholder,
  );

  static Color getButtonColor(CarbonButtonStyle style) {
    switch (style) {
      case CarbonButtonStyle.danger:
        return carbonColorButtonDanger;
      case CarbonButtonStyle.ghost:
        return carbonColorButtonGhost;
      case CarbonButtonStyle.primary:
        return carbonColorButtonPrimary;
      case CarbonButtonStyle.secondary:
        return carbonColorButtonSecondary;
      case CarbonButtonStyle.tertiary:
        return carbonColorButtonTertiary;
    }
  }

  static Color getButtonFontColor(CarbonButtonStyle style) {
    switch (style) {
      case CarbonButtonStyle.danger:
        return carbonColorButtonOnDanger;
      case CarbonButtonStyle.ghost:
        return carbonColorButtonOnGhost;
      case CarbonButtonStyle.primary:
        return carbonColorButtonOnPrimary;
      case CarbonButtonStyle.secondary:
        return carbonColorButtonOnSecondary;
      case CarbonButtonStyle.tertiary:
        return carbonColorButtonOnTertiary;
    }
  }

  static Color getButtonBorderColor(CarbonButtonStyle style) {
    switch (style) {
      case CarbonButtonStyle.danger:
        return carbonColorButtonDanger;
      case CarbonButtonStyle.ghost:
        return carbonColorButtonGhost;
      case CarbonButtonStyle.primary:
        return carbonColorButtonPrimary;
      case CarbonButtonStyle.secondary:
        return carbonColorButtonSecondary;
      case CarbonButtonStyle.tertiary:
        return carbonColorButtonOnTertiary;
    }
  }

  static Color getTileBorderColor(CarbonTileStyle style, bool selected) {
    switch (style) {
      case CarbonTileStyle.base:
        return carbonColorButtonSecondary;
      case CarbonTileStyle.clickable:
        return selected ? carbonColorBorderSubtleSelected03 : carbonColorBorderSubtle03;
      case CarbonTileStyle.selectable:
        return selected ? carbonColorBorderSubtleSelected03 : carbonColorBorderSubtle03;
      case CarbonTileStyle.expandable:
        return selected ? carbonColorBorderSubtleSelected03 : carbonColorBorderSubtle03;
    }
  }

  static Color getTileColor(CarbonTileStyle style) {
    switch (style) {
      case CarbonTileStyle.base:
        return carbonColorButtonTertiary;
      case CarbonTileStyle.clickable:
        return carbonColorButtonTertiary;
      case CarbonTileStyle.selectable:
        return carbonColorButtonTertiary;
      case CarbonTileStyle.expandable:
        return carbonColorButtonTertiary;
    }
  }

  static Color getTileFontColor(CarbonTileStyle style) {
    switch (style) {
      case CarbonTileStyle.base:
        return carbonColorButtonOnTertiary;
      case CarbonTileStyle.clickable:
        return carbonColorButtonOnTertiary;
      case CarbonTileStyle.selectable:
        return carbonColorButtonOnTertiary;
      case CarbonTileStyle.expandable:
        return carbonColorButtonOnTertiary;
    }
  }
}
