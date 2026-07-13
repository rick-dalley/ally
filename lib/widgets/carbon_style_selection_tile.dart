import 'package:flutter/material.dart';
import '../app_theme.dart';

class CarbonSelectionTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final String title;
  final String? subTitle;
  const CarbonSelectionTile({super.key, required this.onTap, required this.title, this.icon, this.subTitle});
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
            color: AppTheme.carbonFieldBorder,
            width: 1,
          ),
        ),
        child: ListTile(
          leading: icon != null
              ? _buildDynamicIcon(isCompleted: true, icon: icon!, activeColor: AppColors.peacockBlue)
              : null,
          title: Text(title),
          subtitle: Text(subTitle ?? ""),
          onTap: onTap,
        ),
      ),
    );
  }
}

Widget _buildDynamicIcon({required bool isCompleted, required IconData icon, required Color activeColor}) {
  return Icon(icon, color: isCompleted ? activeColor : AppColors.greyDepth, size: 24);
}
