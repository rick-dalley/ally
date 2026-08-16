import 'package:flutter/material.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/widgets/carbon_style_separators.dart';
import '../app_theme.dart';

class CarbonActionTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? outlineIcon;
  final Color? iconColor;
  final Size? iconSize;
  final String title;
  final String? subtitle;
  const CarbonActionTile({
    super.key,
    required this.onTap,
    required this.title,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.outlineIcon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Color fontColor = CarbonTheme.getButtonFontColor(CarbonButtonStyle.tertiary);
    Size size = iconSize ?? Size(24, 24);
    Color activeColor = iconColor ?? fontColor;
    // An explicit iconColor means this tile has a real domain identity — let the title
    // and border carry it too, not just the icon. Icon-only color was the icon doing
    // all the work of "which feature is this" alone, which barely moves the needle:
    // title and border tie the whole tile together as one recognizable unit instead.
    Color borderColor = iconColor != null
        ? activeColor.withValues(alpha: 0.4)
        : CarbonTheme.getButtonBorderColor(CarbonButtonStyle.tertiary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            // Subtle border changes color when task is done
            color: borderColor,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsetsGeometry.symmetric(horizontal: 16.0, vertical: 16.0),
          leading: Row(
            mainAxisSize: MainAxisSize.min, // Essential: prevents the Row from taking full width
            children: [
              // Your existing icon logic
              icon != null
                  ? _buildDynamicIcon(
                      isCompleted: true,
                      outlineIcon: outlineIcon ?? icon!,
                      solidIcon: icon!,
                      size: size,
                      activeColor: activeColor,
                    )
                  : const SizedBox.shrink(),
              CarbonVerticalSeparator(height: 64.0, width: 1.0),
              // The vertical divider
            ],
          ),
          title: Text(title, style: CarbonTheme.carbonTertiaryButtonTextStyle.copyWith(color: activeColor)),
          subtitle: Text(subtitle ?? "", style: CarbonTheme.carbonHintTextStyle),
          onTap: onTap,
        ),
      ),
    );
  }
}

Widget _buildDynamicIcon({
  required bool isCompleted,
  required IconData outlineIcon,
  required IconData solidIcon,
  required Color activeColor,
  required Size size,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Icon(
      isCompleted ? solidIcon : outlineIcon,
      color: isCompleted ? activeColor : AppTheme.tertiaryColor,
      size: size.width,
    ),
  );
}
