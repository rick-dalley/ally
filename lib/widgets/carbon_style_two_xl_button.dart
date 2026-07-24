import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

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
    Color carbonBorderColor = carbonColorButtonPrimary;
    Color carbonFontColor = carbonColorButtonOnPrimary;
    Color carbonButtonColor = carbonColorButtonPrimary;
    TextStyle textStyle = CarbonTheme.carbonPrimaryButtonTextStyle;
    switch (buttonStyle) {
      case CarbonButtonStyle.danger:
        carbonBorderColor = carbonColorButtonDanger;
        carbonFontColor = carbonColorButtonOnDanger;
        carbonButtonColor = carbonColorButtonDanger;
      case CarbonButtonStyle.ghost:
        carbonBorderColor = carbonColorButtonGhost;
        carbonFontColor = carbonColorButtonOnGhost;
        carbonButtonColor = carbonColorButtonGhost;
      case CarbonButtonStyle.primary:
        carbonBorderColor = carbonColorButtonPrimary;
        carbonFontColor = carbonColorButtonOnPrimary;
        carbonButtonColor = carbonColorButtonPrimary;
      case CarbonButtonStyle.secondary:
        carbonBorderColor = carbonColorButtonSecondary;
        carbonFontColor = carbonColorButtonOnSecondary;
        carbonButtonColor = carbonColorButtonSecondary;
      case CarbonButtonStyle.tertiary:
        carbonBorderColor = carbonColorButtonTertiary;
        carbonFontColor = carbonColorButtonSecondary;
        carbonButtonColor = carbonColorButtonTertiary;
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
