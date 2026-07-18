import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../classes/carbon_style_constants.dart';

class CarbonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final IconData? icon;
  final MainAxisAlignment alignment;
  final Color? color;
  final CarbonButtonSize? size;
  const CarbonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.isSecondary = false,
    this.icon,
    this.alignment = MainAxisAlignment.start,
    this.size = CarbonButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    // Define the icon and text widgets
    final buttonColor = color ?? AppTheme.lightTheme.primaryColorDark;
    final size = this.size ?? CarbonButtonSize.medium;
    final iconWidget = icon != null ? Icon(icon, size: 20) : null;
    final textWidget = Text(
      label,
      style: GoogleFonts.ibmPlexSans(fontSize: size.fontSize, fontWeight: FontWeight.w400, letterSpacing: 0.16),
    );
    // Determine the list of children based on alignment
    // For 'Right' alignment, we place text first, then icon
    List<Widget> children = [
      textWidget,
      alignment == MainAxisAlignment.center ? const SizedBox(width: 24) : const Spacer(),
      ?iconWidget,
    ];

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppTheme.cancelButtonBackGround : buttonColor,
          foregroundColor: isSecondary ? Colors.black : AppColors.grey.all[0],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(mainAxisAlignment: alignment, children: children),
      ),
    );
  }
}
