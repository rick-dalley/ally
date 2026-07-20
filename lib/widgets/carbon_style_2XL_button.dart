import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/app_theme.dart';
import '../classes/carbon_style_constants.dart';

class CarbonStyle2xlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final CarbonButtonStyle? style;
  final String? topLabel;
  final String? label;
  final double? width;
  final double? height;
  const CarbonStyle2xlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.width,
    this.height,
    this.label,
    this.topLabel,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    CarbonButtonStyle buttonStyle = CarbonButtonStyle.primary;
    Color carbonBorderColor = AppTheme.carbonButtonBorderPrimaryColor;
    Color carbonFontColor = AppTheme.carbonButtonPrimaryFontColor;
    Color carbonButtonColor = AppTheme.carbonButtonPrimaryColor;
    TextStyle textStyle = AppTheme.carbonPrimaryButtonTextStyle;
    switch (buttonStyle) {
      case CarbonButtonStyle.danger:
        carbonBorderColor = AppTheme.carbonButtonBorderDangerColor;
        carbonFontColor = AppTheme.carbonButtonDangerFontColor;
        carbonButtonColor = AppTheme.carbonButtonDangerColor;
      case CarbonButtonStyle.ghost:
        carbonBorderColor = AppTheme.carbonButtonBorderGhostColor;
        carbonFontColor = AppTheme.carbonButtonGhostFontColor;
        carbonButtonColor = AppTheme.carbonButtonGhostColor;
      case CarbonButtonStyle.primary:
        carbonBorderColor = AppTheme.carbonButtonBorderPrimaryColor;
        carbonFontColor = AppTheme.carbonButtonPrimaryFontColor;
        carbonButtonColor = AppTheme.carbonButtonPrimaryColor;
      case CarbonButtonStyle.secondary:
        carbonBorderColor = AppTheme.carbonButtonBorderSecondaryColor;
        carbonFontColor = AppTheme.carbonButtonSecondaryFontColor;
        carbonButtonColor = AppTheme.carbonButtonSecondaryColor;
      case CarbonButtonStyle.tertiary:
        carbonBorderColor = AppTheme.carbonButtonBorderTertiaryColor;
        carbonFontColor = AppTheme.carbonButtonTertiaryFontColor;
        carbonButtonColor = AppTheme.carbonButtonTertiaryColor;
    }
    String lbl = label ?? "";
    String tpLbl = topLabel ?? "";
    final double w = width ?? 184;
    final double h = height ?? CarbonButtonSize.extraExtraLarge.height;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: carbonButtonColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: carbonBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Now the column shrinks to fit content
              children: [
                Text(
                  tpLbl,
                  style: GoogleFonts.ibmPlexSans(
                    color: carbonFontColor,
                    fontSize: CarbonButtonSize.small.fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  lbl,
                  style: GoogleFonts.ibmPlexSans(
                    color: carbonFontColor,
                    fontSize: CarbonButtonSize.large.fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Spacer(), // Gap between text and icon
            Icon(icon, color: carbonFontColor, size: 24),
          ],
        ),
      ),
    );
  }
}
