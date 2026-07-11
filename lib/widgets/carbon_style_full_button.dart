import 'package:flutter/material.dart';

import '../classes/carbon_style_constants.dart';

class CarbonFullButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double? width;
  final CarbonButtonSize? size;
  final FontWeight? fontWeight;
  final double? overRideHeight;
  const CarbonFullButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    this.size,
    this.fontWeight,
    this.width,
    this.overRideHeight,
  });

  @override
  State<StatefulWidget> createState() => CarbonFullButtonState();
}

class CarbonFullButtonState extends State<CarbonFullButton> {
  CarbonButtonSize size = CarbonButtonSize.medium;
  double height = 0;
  double width = 0;
  FontWeight fontWeight = FontWeight.w400;
  Color color = Colors.transparent;
  @override
  void initState() {
    super.initState();
    if (widget.size != null) {
      size = widget.size!;
      height = widget.overRideHeight ?? size.height;
      fontWeight = widget.fontWeight ?? FontWeight.w400;
      color = widget.color;
    }
  }

  // Inside build method
  @override
  Widget build(BuildContext context) {
    final double displayWidth = widget.width ?? MediaQuery.of(context).size.width;
    final double verticalPadding = size.verticalPadding;

    return SizedBox(
      width: displayWidth,
      height: size.height,
      child: OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes extra touch padding
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
          foregroundColor: widget.color,
          side: BorderSide(color: widget.color, width: 1),
          backgroundColor: widget.color.withAlpha(20),
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: size.fontSize, // Fixed font size as requested
                  fontWeight: widget.fontWeight ?? FontWeight.w400,
                  color: widget.color,
                  letterSpacing: -0.2,
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
