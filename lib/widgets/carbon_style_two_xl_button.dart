import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    CarbonButtonStyle buttonStyle = style ?? CarbonButtonStyle.primary;
    Color borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);
    Color fontColor = CarbonTheme.getButtonFontColor(buttonStyle);
    Color buttonColor = CarbonTheme.getButtonColor(buttonStyle);
    String lbl = label ?? "";
    String tpLbl = topLabel ?? "";
    final double w = width ?? 184;
    final double h = height ?? CarbonButtons.extraExtraLarge.height;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: w,
        // Fixed, not a floor — this card is designed as exactly two lines
        // (a small overline label, a large value), always the same height
        // as its sibling card next to it.
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Expanded, not a bare Column — bounds the label's width to the
            // space left after the icon so a long label ellipsizes there
            // (last-resort only) instead of overflowing the card.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tpLbl,
                    style: GoogleFonts.ibmPlexSans(
                      color: fontColor,
                      // Carbon's caption-01/label-01 overline size (12px),
                      // not the button-label extraSmall token (14px) — at
                      // 14px "Body Mass Index" doesn't fit this card's
                      // width on one line, which this two-line design
                      // requires.
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    lbl,
                    style: GoogleFonts.ibmPlexSans(
                      color: fontColor,
                      fontSize: CarbonButtons.large.fontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: CarbonSpacing.narrow.width), // Gap between text and icon
            Icon(icon, color: fontColor, size: 24),
          ],
        ),
      ),
    );
  }
}
