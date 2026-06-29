import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/acuity.dart';

class AcuityStyle {
  final Color color;
  final Color iconColor;
  final Color backgroundColor;
  final IconData icon;
  final int weight;
  final bool fill;

  AcuityStyle({
    required this.color,
    required this.iconColor,
    required this.backgroundColor,
    required this.icon,
    required this.weight,
    required this.fill,
  });
}

// Use these for text and borders (high saturation, high contrast)
Map<AcuityLevel, AcuityStyle> acuityStyles = {
  AcuityLevel.resuscitate: AcuityStyle(
    color: Color(0xFF0F62FE),
    iconColor: Colors.white,
    backgroundColor: Color(0xFFF4F8FF),
    icon: Symbols.emergency,
    weight: 700,
    fill: true,
  ),
  AcuityLevel.emergent: AcuityStyle(
    color: Color(0xFFDA1E28),
    iconColor: Colors.white,
    backgroundColor: Color(0xFFFFF1F1),
    icon: Symbols.emergency,
    weight: 600,
    fill: true,
  ),
  AcuityLevel.urgent: AcuityStyle(
    color: Color(0xFFFA4D56),
    iconColor: Colors.white,
    backgroundColor: Color(0xFFFFF8F2),
    icon: Symbols.emergency,
    weight: 500,
    fill: true,
  ),
  AcuityLevel.lessUrgent: AcuityStyle(
    color: Color(0xFF755D00),
    iconColor: Colors.white,
    backgroundColor: Color(0xFFFFFDE0),
    icon: Symbols.emergency,
    weight: 400,
    fill: true,
  ),
  AcuityLevel.notUrgent: AcuityStyle(
    color: Colors.black45,
    iconColor: Colors.white70,
    backgroundColor: Colors.white70,
    icon: Symbols.emergency,
    weight: 200,
    fill: false,
  ),
};
AcuityStyle blankAcuityStyle = AcuityStyle(
  color: Colors.grey,
  iconColor: Colors.white70,
  icon: Symbols.help,
  backgroundColor: Colors.white70,
  weight: 200,
  fill: false,
);

class AcuityIndicator extends StatelessWidget {
  final AcuityLevel status;

  const AcuityIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = acuityStyles[status] ?? blankAcuityStyle;
    final Widget icon = Icon(
      style.icon,
      size: 24,
      color: style.iconColor,
      fill: style.fill ? 1.0 : 0.0,
      weight: style.weight.toDouble(),
    );

    return Container(
      // Increased padding for more breathing room
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: style.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: style.color,
            child: status == AcuityLevel.resuscitate ? HaloWidget(child: icon) : icon,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              status.label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5, // Added letter spacing for readability
                color: style.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HaloWidget extends StatefulWidget {
  final Widget child;
  const HaloWidget({super.key, required this.child});

  @override
  State<HaloWidget> createState() => _HaloWidgetState();
}

class _HaloWidgetState extends State<HaloWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(painter: ClinicalRipplePainter(_controller.value), child: widget.child);
      },
    );
  }
}

class ClinicalRipplePainter extends CustomPainter {
  final double progress;
  ClinicalRipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Use a thicker, more deliberate stroke
    final paint = Paint()
      ..color = const Color(0xFF0F62FE).withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // A single, heavy ripple that feels grounded
    final radius = progress * (size.width * 0.7);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(ClinicalRipplePainter oldDelegate) => true;
}
