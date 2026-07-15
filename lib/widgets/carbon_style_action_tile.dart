import 'package:flutter/material.dart';
import '../app_theme.dart';

class CarbonActionTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? outlineIcon;
  final Color? iconColor;
  final Size? iconSize;
  final String title;
  final String? subTitle;
  const CarbonActionTile({
    super.key,
    required this.onTap,
    required this.title,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.outlineIcon,
    this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    Size size = iconSize ?? Size(24, 24);
    Color activeColor = iconColor ?? AppTheme.lightTheme.primaryColorDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            // Subtle border changes color when task is done
            color: AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: ListTile(
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

              // The vertical divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 1, // Thickness
                  height: 40, // Fixed height to make it shorter than the tile
                  color: AppColors.grey.all[3], // Your preferred divider color
                ),
              ),
            ],
          ),
          title: Text(title),
          subtitle: Text(subTitle ?? ""),
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
  return Icon(
    isCompleted ? solidIcon : outlineIcon,
    color: isCompleted ? activeColor : AppColors.greyDepth,
    size: size.width,
  );
}
