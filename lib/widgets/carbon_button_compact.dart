import 'package:flutter/material.dart';
import 'package:triage/classes/carbon_theme_constants.dart';

class CarbonCompactButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final CarbonButtonStyle? style;
  const CarbonCompactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.style,
    this.width,
    this.height,
  });

  @override
  State<StatefulWidget> createState() => CarbonCompactButtonState();
}

class CarbonCompactButtonState extends State<CarbonCompactButton> {
  late CarbonButtonStyle buttonStyle;
  late Color buttonColor;
  late Color borderColor;
  late Color fontColor;
  @override
  void initState() {
    super.initState();
    buttonStyle = widget.style ?? CarbonButtonStyle.primary;
    buttonColor = CarbonTheme.getButtonColor(buttonStyle);
    borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);
    fontColor = CarbonTheme.getButtonFontColor(buttonStyle);
  }

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;
    double width = widget.width ?? availableWidth;
    // Adjusted for margins
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          foregroundColor: fontColor,
          side: BorderSide(color: borderColor, width: 1),
          backgroundColor: buttonColor,
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 22), // Slightly larger icon
            const SizedBox(height: 4),
            Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
