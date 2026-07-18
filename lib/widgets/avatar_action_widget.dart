import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';

class AvatarActionWidget extends StatelessWidget {
  final Function(int) onTap;
  final String? label;
  final dynamic value;
  final double width;
  final double height;
  final Color? color;
  final Widget? avatar;
  final TextStyle? textStyle;

  const AvatarActionWidget({
    super.key,
    required this.onTap,
    this.label,
    this.value = 0,
    this.width = 64,
    this.height = 64,
    this.color,
    this.avatar,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.lightTheme.primaryColor;
    final style = textStyle ?? TextStyle(fontSize: 14, color: AppTheme.carbonFieldFontColor);

    return InkWell(
      onTap: () => onTap(value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(width * 0.5 + 4), // Circular avatar
            ),
            child: Center(child: avatar ?? Icon(Symbols.person_rounded, color: AppColors.grey.all[0])),
          ),
          if (label != null) ...[const SizedBox(height: 8), Text(label!, style: style)],
        ],
      ),
    );
  }
}
