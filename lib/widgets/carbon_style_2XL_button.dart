import 'package:flutter/material.dart';
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
    String lbl = label ?? "";
    String tpLbl = topLabel ?? "";
    CarbonButtonStyle cbs = style ?? CarbonButtonStyle.primary;
    final double w = width ?? 184;
    final double h = height ?? CarbonButtonSize.extraExtraLarge.height;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cbs == CarbonButtonStyle.ghost ? AppColors.grey.all[1] : AppTheme.lightTheme.primaryColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: cbs == CarbonButtonStyle.ghost ? AppTheme.carbonFieldBorder : AppTheme.lightTheme.primaryColor,
          ),
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
                  style: cbs == CarbonButtonStyle.ghost
                      ? AppTheme.carbonTinyTextStyle
                      : AppTheme.carbonTinyTextStyleOnPrimary,
                ),
                Text(
                  lbl,
                  style: cbs == CarbonButtonStyle.ghost
                      ? AppTheme.carbonGhostButtonTextStyle
                      : AppTheme.carbonPrimaryButtonTextStyle,
                ),
              ],
            ),
            Spacer(), // Gap between text and icon
            Icon(
              icon,
              color: cbs == CarbonButtonStyle.ghost ? AppTheme.carbonLabelFontColor : AppColors.grey.all[0],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
