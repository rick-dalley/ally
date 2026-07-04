import 'package:flutter/material.dart';

class CarbonCompactButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const CarbonCompactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<StatefulWidget> createState() => CarbonCompactButtonState();
}

class CarbonCompactButtonState extends State<CarbonCompactButton> {
  @override
  Widget build(BuildContext context) {
    Color color = widget.color;
    double availableWidth = MediaQuery.of(context).size.width - 80; // Adjusted for margins
    return SizedBox(
      width: availableWidth / 4,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 22), // Slightly larger icon
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                letterSpacing: -0.2, // Tighter letters to prevent overflow
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
