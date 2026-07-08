import 'package:flutter/material.dart';

class CarbonFullButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double? width;
  final double? height;
  final double? fontsSize;
  final FontWeight? fontWeight;
  const CarbonFullButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    this.fontsSize,
    this.fontWeight,
    this.width,
    this.height,
  });

  @override
  State<StatefulWidget> createState() => CarbonFullButtonState();
}

class CarbonFullButtonState extends State<CarbonFullButton> {
  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;
    double width = widget.width ?? availableWidth;
    FontWeight fontWeight = widget.fontWeight ?? FontWeight.w400;
    Color color = widget.color;
    double fontSize = widget.fontsSize ?? 20;
    // Adjusted for margins
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          backgroundColor: color.withAlpha(20),
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.all(24),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  letterSpacing: -0.2, // Tighter letters to prevent overflow
                ),
                maxLines: 1,
              ),
            ),
            Spacer(),
            Padding(padding: EdgeInsetsGeometry.all(24), child: Icon(widget.icon, size: 24)), // Slightly larger icon
          ],
        ),
      ),
    );
  }
}
