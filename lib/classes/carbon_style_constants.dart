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

enum CarbonButtonStyle { ghost, primary }

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
        return 14;
      case CarbonButtonSize.medium:
        return 16;
      case CarbonButtonSize.large:
        return 18;
      case CarbonButtonSize.largeBold:
      case CarbonButtonSize.extraLarge:
      case CarbonButtonSize.extraExtraLarge:
        return 20;
    }
  }
}
