import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../classes/carbon_theme_constants.dart';

class CarbonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final MainAxisAlignment alignment;
  final CarbonButtonStyle? style;
  final CarbonButtons? size;
  const CarbonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = CarbonButtons.medium,
    this.alignment = MainAxisAlignment.start,
    this.style = CarbonButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    // Define the icon and text widgets
    CarbonButtonStyle buttonStyle = style ?? CarbonButtonStyle.primary;
    final buttonColor = CarbonTheme.getButtonColor(buttonStyle);
    final textColor = CarbonTheme.getButtonFontColor(buttonStyle);
    final iconColor = textColor;
    final borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);

    final size = this.size ?? CarbonButtons.medium;
    final iconWidget = icon != null ? Icon(icon, size: 20, color: iconColor) : null;
    final textWidget = Text(
      label,
      style: GoogleFonts.ibmPlexSans(fontSize: size.fontSize, fontWeight: FontWeight.w400, letterSpacing: 0.14),
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
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          // Add the side property here:
          side: BorderSide(
            color: borderColor, // Your border color
            width: 1.0, // Your border width (optional, defaults to 1.0)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(mainAxisAlignment: alignment, children: children),
      ),
    );
  }
}

class CarbonIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData? icon;
  final MainAxisAlignment alignment;
  final CarbonButtonStyle? style;
  final CarbonIconButtons? carbonIconButton;
  const CarbonIconButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.carbonIconButton = CarbonIconButtons.medium,
    this.alignment = MainAxisAlignment.start,
    this.style = CarbonButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    // Define the icon and text widgets
    CarbonButtonStyle buttonStyle = style ?? CarbonButtonStyle.primary;
    final buttonColor = CarbonTheme.getButtonColor(buttonStyle);
    final iconColor = CarbonTheme.getButtonFontColor(buttonStyle);
    final borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);
    carbonIconButton ?? CarbonIconButtons.medium.size;
    final Size size = carbonIconButton!.size;
    final iconWidget = icon != null ? Icon(icon, size: carbonIconButton!.iconSize.height, color: iconColor) : null;

    return SizedBox(
      height: size.height,
      width: size.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: iconColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          // Add the side property here:
          padding: EdgeInsets.symmetric(
            horizontal: carbonIconButton!.paddingSize.width,
            vertical: carbonIconButton!.paddingSize.height,
          ),
          elevation: 0,
        ),
        child: iconWidget,
      ),
    );
  }
}

class CarbonAcceptButton extends StatelessWidget {
  final String label;
  final Function(bool) onAccepted;
  final MainAxisAlignment alignment;
  final CarbonButtonStyle? style;
  final CarbonButtons? size;

  const CarbonAcceptButton({
    super.key,
    required this.label,
    required this.onAccepted,
    this.size = CarbonButtons.medium,
    this.alignment = MainAxisAlignment.start,
    this.style = CarbonButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    // Define the icon and text widgets
    CarbonButtonStyle buttonStyle = style ?? CarbonButtonStyle.primary;
    final buttonColor = CarbonTheme.getButtonColor(buttonStyle);
    final textColor = CarbonTheme.getButtonFontColor(buttonStyle);
    final iconColor = textColor;
    final borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);

    final size = this.size ?? CarbonButtons.medium;

    final textWidget = Text(label, style: CarbonTheme.carbonPrimaryButtonTextStyle);

    return Container(
      color: buttonColor,
      height: size.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(width: 16.0),
          Expanded(child: textWidget),
          CarbonIconButton(onPressed: () => onAccepted(false), icon: Symbols.cancel),
          CarbonIconButton(onPressed: () => onAccepted(true), icon: Symbols.check),
        ],
      ),
    );
  }
}
