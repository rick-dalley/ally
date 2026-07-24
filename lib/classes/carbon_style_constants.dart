import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'app_colors.dart';

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
  static Color carbonWhite = Color(0xFFFFFFFF);
  static Color carbonPrimary = AppTheme.primaryColor;
  static Color carbonOnPrimary = carbonWhite;
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
    color: AppTheme.onPrimaryColor,
  );
  static TextStyle carbonGhostButtonTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonLabelFontColor,
  );
  static TextStyle? carbonExpressiveTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: carbonHeaderFontColor,
  );

  static TextStyle? carbonTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: carbonLabelFontColor,
  );

  static TextStyle? carbonTinyTextStyle = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    color: carbonLabelFontColor,
  );

  static TextStyle? carbonTinyTextStyleOnPrimary = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    color: AppTheme.onPrimaryColor,
  );
}
