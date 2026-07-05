import 'package:flutter/material.dart';
import '../app_theme.dart';

class CarbonActionTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? outlineIcon;
  final String title;
  final String? subTitle;
  const CarbonActionTile({
    super.key,
    required this.onTap,
    required this.title,
    this.icon,
    this.outlineIcon,
    this.subTitle,
  });
  @override
  Widget build(BuildContext context) {
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
          leading: icon != null
              ? _buildDynamicIcon(
                  isCompleted: true,
                  outlineIcon: outlineIcon ?? icon!,
                  solidIcon: icon!,
                  activeColor: AppTheme.deepLogicViolet,
                )
              : null,
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
}) {
  return Icon(
    isCompleted ? solidIcon : outlineIcon,
    color: isCompleted ? activeColor : AppTheme.deepCharcoal,
    size: 24,
  );
}
