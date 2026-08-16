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
          minimumSize: Size(0, widget.height ?? CarbonButtons.small.height),
          padding: EdgeInsets.symmetric(
            vertical: CarbonButtons.small.verticalPadding,
            horizontal: CarbonSpacing.narrow.width,
          ),
          foregroundColor: fontColor,
          side: BorderSide(color: borderColor, width: 1),
          backgroundColor: buttonColor,
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        // Carbon requires icon and label on the same row, icon trailing the
        // text — never stacked. Stacking them (the previous layout) is what
        // forced the font down to 12px and the icon down to a cramped,
        // made-up size just to fit; sized from the same CarbonButtons/
        // CarbonIcons/CarbonSpacing token scale the rest of the button
        // family already uses.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: CarbonButtons.extraSmall.fontSize,
                  fontWeight: FontWeight.w400,
                  color: fontColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: CarbonSpacing.narrow.width),
            Icon(widget.icon, size: CarbonIcons.small.size.width, color: fontColor),
          ],
        ),
      ),
    );
  }
}
