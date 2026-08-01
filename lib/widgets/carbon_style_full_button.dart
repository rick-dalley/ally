import 'package:flutter/material.dart';

import '../classes/carbon_theme_constants.dart';

class CarbonFullButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? width;
  final CarbonButtons? size;
  final CarbonButtonStyle? style;
  final double? overRideHeight;
  const CarbonFullButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.size,
    this.style,
    this.width,
    this.overRideHeight,
  });

  @override
  State<StatefulWidget> createState() => CarbonFullButtonState();
}

class CarbonFullButtonState extends State<CarbonFullButton> {
  late CarbonButtonStyle buttonStyle = widget.style ?? CarbonButtonStyle.primary;
  late CarbonButtons buttonSize = widget.size ?? CarbonButtons.extraLarge;
  late double height = widget.overRideHeight ?? buttonSize.fontSize;
  double width = 0;
  FontWeight fontWeight = FontWeight.w400;
  late Color buttonColor = CarbonTheme.getButtonColor(buttonStyle);
  late Color borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);
  late Color fontColor = CarbonTheme.getButtonFontColor(buttonStyle);
  @override
  void initState() {
    super.initState();
    buttonStyle = widget.style ?? CarbonButtonStyle.primary;
    buttonColor = CarbonTheme.getButtonColor(buttonStyle);
    borderColor = CarbonTheme.getButtonBorderColor(buttonStyle);
    fontColor = CarbonTheme.getButtonFontColor(buttonStyle);
    fontWeight = FontWeight.w400;
    buttonSize = widget.size ?? CarbonButtons.extraLarge;
    height = widget.overRideHeight ?? buttonSize.height;
  }

  // Inside build method
  @override
  Widget build(BuildContext context) {
    final double displayWidth = widget.width ?? MediaQuery.of(context).size.width;
    final double verticalPadding = buttonSize.verticalPadding;

    return SizedBox(
      width: displayWidth,
      height: height,
      child: OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes extra touch padding
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
          foregroundColor: fontColor,
          side: BorderSide(color: borderColor, width: 1),
          backgroundColor: buttonColor,
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: buttonSize.fontSize, // Fixed font size as requested
                  fontWeight: FontWeight.w400,
                  color: fontColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(widget.icon, size: 20),
          ],
        ),
      ),
    );
  }
}
