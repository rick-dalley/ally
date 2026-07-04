import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';

class CarbonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final IconData? icon;
  final MainAxisAlignment alignment;
  final Color? color;
  const CarbonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.isSecondary = false,
    this.icon,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    // Define the icon and text widgets
    final iconWidget = icon != null ? Icon(icon, size: 18) : null;
    final textWidget = Text(
      label,
      style: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.16),
    );
    // Determine the list of children based on alignment
    // For 'Right' alignment, we place text first, then icon
    List<Widget> children = [
      textWidget,
      alignment == MainAxisAlignment.center ? const SizedBox(width: 24) : const Spacer(),
      ?iconWidget,
    ];

    Color secondaryBackgroundColor = color ?? AppTheme.deepLogicViolet;
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? secondaryBackgroundColor : AppTheme.deepLogicViolet,
          foregroundColor: isSecondary ? Colors.black : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(mainAxisAlignment: alignment, children: children),
      ),
    );
  }
}
