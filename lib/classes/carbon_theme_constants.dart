import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

enum CarbonButtonStyle { danger, ghost, primary, secondary, tertiary, stepper }

enum CarbonTileStyle { base, clickable, selectable, expandable }

enum CarbonTileFeatureFlags { single, multi, interactive }

enum CarbonButtons { extraSmall, small, medium, large, largeBold, extraLarge, extraExtraLarge }

extension CarbonButtonSizeHeight on CarbonButtons {
  double get height {
    switch (this) {
      case CarbonButtons.extraSmall:
        return 32;
      case CarbonButtons.small:
        return 40;
      case CarbonButtons.medium:
        return 48;
      case CarbonButtons.large:
      case CarbonButtons.largeBold:
        return 56;
      case CarbonButtons.extraLarge:
        return 64;
      case CarbonButtons.extraExtraLarge:
        return 72;
    }
  }
}

enum CarbonIcons { extraSmall, small, medium, large, largeBold, extraLarge, extraExtraLarge }

extension CarbonIconSixe on CarbonIcons {
  Size get size {
    switch (this) {
      case CarbonIcons.extraSmall:
        return Size(12, 12);
      case CarbonIcons.small:
        return Size(16, 16);
      case CarbonIcons.medium:
        return Size(24, 24);
      case CarbonIcons.large:
      case CarbonIcons.largeBold:
        return Size(32, 32);
      case CarbonIcons.extraLarge:
        return Size(40, 40);
      case CarbonIcons.extraExtraLarge:
        return Size(48, 48);
    }
  }
}

enum CarbonIconButtons { extraSmall, small, medium, large, largeBold, extraLarge, extraExtraLarge }

extension CarbonIconButtonSize on CarbonIconButtons {
  Size get size {
    switch (this) {
      case CarbonIconButtons.extraSmall:
        return Size(32, 32);
      case CarbonIconButtons.small:
        return Size(40, 40);
      case CarbonIconButtons.medium:
        return Size(48, 48);
      case CarbonIconButtons.large:
      case CarbonIconButtons.largeBold:
        return Size(56, 56);
      case CarbonIconButtons.extraLarge:
        return Size(64, 64);
      case CarbonIconButtons.extraExtraLarge:
        return Size(72, 72);
    }
  }
}

extension CarbonIconButtonIconSize on CarbonIconButtons {
  Size get iconSize {
    switch (this) {
      case CarbonIconButtons.extraSmall:
        return Size(12, 12);
      case CarbonIconButtons.small:
        return Size(16, 16);
      case CarbonIconButtons.medium:
        return Size(24, 24);
      case CarbonIconButtons.large:
      case CarbonIconButtons.largeBold:
        return Size(32, 32);
      case CarbonIconButtons.extraLarge:
        return Size(40, 40);
      case CarbonIconButtons.extraExtraLarge:
        return Size(48, 48);
    }
  }
}

extension CarbonIconButtonIconPaddingSize on CarbonIconButtons {
  Size get paddingSize {
    switch (this) {
      case CarbonIconButtons.extraSmall:
      case CarbonIconButtons.small:
      case CarbonIconButtons.medium:
      case CarbonIconButtons.large:
      case CarbonIconButtons.largeBold:
      case CarbonIconButtons.extraLarge:
      case CarbonIconButtons.extraExtraLarge:
        return Size(4, 4);
    }
  }
}

extension CarbonButtonVerticalPadding on CarbonButtons {
  double get verticalPadding {
    switch (this) {
      case CarbonButtons.extraSmall:
        return 4;
      case CarbonButtons.small:
        return 6;
      case CarbonButtons.medium:
        return 8;
      case CarbonButtons.large:
        return 12;
      case CarbonButtons.largeBold:
        return 10;
      case CarbonButtons.extraLarge:
        return 16;
      case CarbonButtons.extraExtraLarge:
        return 24;
    }
  }
}

extension CarbonButtonFontSize on CarbonButtons {
  double get fontSize {
    switch (this) {
      case CarbonButtons.extraSmall:
        return 14;
      case CarbonButtons.small:
        return 16;
      case CarbonButtons.medium:
        return 18;
      case CarbonButtons.large:
      case CarbonButtons.largeBold:
      case CarbonButtons.extraLarge:
        return 20;
      case CarbonButtons.extraExtraLarge:
        return 22;
    }
  }
}

enum CarbonInputs { extraSmall, small, medium, large, largeBold, extraLarge, extraExtraLarge }

extension CarbonInputSize on CarbonInputs {
  Size get size {
    switch (this) {
      case CarbonInputs.extraSmall:
        return Size(32, 32);
      case CarbonInputs.small:
        return Size(40, 40);
      case CarbonInputs.medium:
        return Size(48, 48);
      case CarbonInputs.large:
      case CarbonInputs.largeBold:
        return Size(56, 56);
      case CarbonInputs.extraLarge:
        return Size(64, 64);
      case CarbonInputs.extraExtraLarge:
        return Size(72, 72);
    }
  }
}

extension CarbonInputEdgeInsetSize on CarbonInputs {
  Size get edgeInsetSize {
    switch (this) {
      case CarbonInputs.extraSmall:
      case CarbonInputs.small:
      case CarbonInputs.medium:
      case CarbonInputs.large:
      case CarbonInputs.largeBold:
      case CarbonInputs.extraLarge:
      case CarbonInputs.extraExtraLarge:
        return Size(12, 12);
    }
  }
}

class CarbonTheme {
  static TextStyle carbonHeadingTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.extraExtraLarge.fontSize,
    color: carbonColorTextPrimary,
  );

  static TextStyle carbonPrimaryButtonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
    color: carbonColorButtonOnPrimary,
    backgroundColor: carbonColorButtonPrimary,
  );

  static TextStyle carbonGhostButtonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.large.fontSize,
    color: carbonColorButtonGhost,
    backgroundColor: carbonColorButtonTertiary,
  );

  static TextStyle carbonTertiaryButtonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
    color: carbonColorButtonOnTertiary,
  );

  static TextStyle? carbonExpressiveTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.extraExtraLarge.fontSize,
    color: AppTheme.primaryColor,
  );

  static TextStyle? carbonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
    color: carbonColorTextPrimary,
  );

  static TextStyle? carbonLabelTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.small.fontSize,
    color: carbonColorTextSecondary,
  );

  static TextStyle? carbonFieldTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
    color: carbonColorTextPrimary,
  );
  static TextStyle? dangerTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
    color: carbonColorButtonOnDanger,
  );
  static TextStyle? carbonLabelOnPrimary = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
    color: carbonColorButtonOnPrimary,
  );

  static TextStyle? carbonHelperLabelOnPrimary = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.small.fontSize,
    color: carbonColorButtonOnPrimary,
  );

  static TextStyle? carbonHelperTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.small.fontSize,
    color: carbonColorTextHelper,
  );

  static TextStyle? carbonHintTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.small.fontSize,
    color: carbonColorTextHelper,
  );

  static TextStyle? carbonPlaceholderTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: CarbonButtons.medium.fontSize,
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
      case CarbonButtonStyle.stepper:
        return Color(0x00000000);
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
      case CarbonButtonStyle.stepper:
        return carbonColorIconSecondary;
    }
  }

  static Color getButtonIconColor(CarbonButtonStyle style) {
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
      case CarbonButtonStyle.stepper:
        return carbonColorIconSecondary;
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
      case CarbonButtonStyle.stepper:
        return Color(0x00000000);
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
