import 'package:flutter/material.dart';

class HighLowCloseCapsule extends StatelessWidget {
  final double current; // 'o' - most recent reading
  final double historicalMin; // 'L' - patient's lowest historical reading
  final double historicalMax; // 'H' - patient's highest reading
  final double clinicalMin; // bottom boundary of healthy range
  final double clinicalMax; // top boundary of healthy range
  final double height; // Available height for the capsule core
  final Color color;
  final Color alertColor;
  final Color inactiveColor;

  const HighLowCloseCapsule({
    super.key,
    required this.current,
    required this.historicalMin,
    required this.historicalMax,
    required this.clinicalMin,
    required this.clinicalMax,
    required this.height,
    required this.color,
    this.inactiveColor = Colors.grey,
    this.alertColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    const double capsuleWidth = 16.0;
    const double margin = 16.0; // Extra padding top and bottom for floating out-of-bounds dots
    final double totalHeight = height + (margin * 2);

    final bool isInactive = current == 0 && historicalMin == 0 && historicalMax == 0;
    final bool isOutlier = !isInactive && (current > clinicalMax || current < clinicalMin);
    final Color activeColor = isInactive ? inactiveColor : (isOutlier ? alertColor : color);

    return SizedBox(
      width: capsuleWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. The capsule painter handles the background, clinical bounds, historical span, and clamped capsule elements
          Positioned(
            top: margin,
            child: CustomPaint(
              size: Size(capsuleWidth, height),
              painter: HlcCapsulePainter(
                current: current,
                historicalMin: historicalMin,
                historicalMax: historicalMax,
                clinicalMin: clinicalMin,
                clinicalMax: clinicalMax,
                color: activeColor,
                isInactive: isInactive,
              ),
            ),
          ),
          // 2. If it's an outlier, render the floating dot and ripple halo completely unconstrained by the capsule bounds
          if (isOutlier)
            HlcOutlierOverlay(
              current: current,
              clinicalMin: clinicalMin,
              clinicalMax: clinicalMax,
              height: height,
              margin: margin,
              capsuleWidth: capsuleWidth,
              color: activeColor,
            ),
        ],
      ),
    );
  }
}

class HlcCapsulePainter extends CustomPainter {
  final double current;
  final double historicalMin;
  final double historicalMax;
  final double clinicalMin;
  final double clinicalMax;
  final Color color;
  final bool isInactive;

  HlcCapsulePainter({
    required this.current,
    required this.historicalMin,
    required this.historicalMax,
    required this.clinicalMin,
    required this.clinicalMax,
    required this.color,
    required this.isInactive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    if (isInactive) {
      final Rect clinicalRect = Rect.fromLTWH(0, 0, size.width, size.height);
      final RRect clinicalRRect = RRect.fromRectAndRadius(clinicalRect, Radius.circular(radius));

      final Paint borderPaint = Paint()
        ..color = color.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(clinicalRRect, borderPaint);
      return;
    }

    final double innerHeight = size.height - size.width;
    final double clinicalRange = clinicalMax - clinicalMin;

    double getY(double val) {
      if (clinicalRange <= 0) return size.height / 2;
      final double normalized = (val - clinicalMin) / clinicalRange;
      return radius + (innerHeight * (1.0 - normalized));
    }

    // 1. Draw Outer Healthy Capsule (Clinical Min/Max bounds)
    final Rect clinicalRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect clinicalRRect = RRect.fromRectAndRadius(clinicalRect, Radius.circular(radius));

    final Paint backgroundPaint = Paint()
      ..color = color.withAlpha(20)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(clinicalRRect, backgroundPaint);

    final Paint borderPaint = Paint()
      ..color = color.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(clinicalRRect, borderPaint);

    // 2. Draw Inner Historical Capsule (Patient Min/Max bounds nested inside, clamped to clinical range)
    final double yH = getY(historicalMax).clamp(radius, size.height - radius);
    final double yL = getY(historicalMin).clamp(radius, size.height - radius);

    final double topY = yH < yL ? yH : yL;
    final double bottomY = yH > yL ? yH : yL;
    final double spanHeight = bottomY - topY;

    if (spanHeight > 0) {
      final Rect spanRect = Rect.fromLTRB(0, topY - radius, size.width, bottomY + radius);
      final RRect spanRRect = RRect.fromRectAndRadius(spanRect, Radius.circular(radius));

      final Paint spanPaint = Paint()
        ..color = color.withAlpha(90)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(spanRRect, spanPaint);
    }

    // 3. Draw Most Recent Reading Dot ONLY if it is inside the normal range.
    // Outliers are handled separately by the unconstrained overlay so they float outside.
    if (current >= clinicalMin && current <= clinicalMax) {
      final double yCurrent = getY(current).clamp(radius, size.height - radius);
      final Paint dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width / 2, yCurrent), radius * 0.7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HlcCapsulePainter oldDelegate) {
    return oldDelegate.current != current ||
        oldDelegate.historicalMin != historicalMin ||
        oldDelegate.historicalMax != historicalMax ||
        oldDelegate.clinicalMin != clinicalMin ||
        oldDelegate.clinicalMax != clinicalMax ||
        oldDelegate.color != color ||
        oldDelegate.isInactive != isInactive;
  }
}

class HlcOutlierOverlay extends StatelessWidget {
  final double current;
  final double clinicalMin;
  final double clinicalMax;
  final double height;
  final double margin;
  final double capsuleWidth;
  final Color color;

  const HlcOutlierOverlay({
    super.key,
    required this.current,
    required this.clinicalMin,
    required this.clinicalMax,
    required this.height,
    required this.margin,
    required this.capsuleWidth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = capsuleWidth / 2;
    final double innerHeight = height - capsuleWidth;
    final double clinicalRange = clinicalMax - clinicalMin;

    double getY(double val) {
      if (clinicalRange <= 0) return height / 2;
      final double normalized = (val - clinicalMin) / clinicalRange;
      return radius + (innerHeight * (1.0 - normalized));
    }

    // Calculate Y position relative to the capsule core, then add top margin offset
    double coreY = getY(current);
    if (current > clinicalMax) {
      // Float above the top cap
      coreY = coreY.clamp(-margin + radius, radius);
    } else if (current < clinicalMin) {
      // Float below the bottom cap
      coreY = coreY.clamp(height - radius, height + margin - radius);
    }

    final double absoluteY = margin + coreY;

    return Positioned(
      top: absoluteY - radius,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          width: capsuleWidth,
          height: capsuleWidth,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const HlcRippleEffect(),
              Container(
                width: capsuleWidth * 0.7,
                height: capsuleWidth * 0.7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HlcRippleEffect extends StatefulWidget {
  const HlcRippleEffect({super.key});

  @override
  HlcRippleEffectState createState() => HlcRippleEffectState();
}

class HlcRippleEffectState extends State<HlcRippleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double progress = _controller.value;
        final double opacity = (1.0 - progress);
        // Larger, more prominent max ripple size (e.g. up to 32px diameter)
        const double baseSize = 16.0;
        final double currentSize = baseSize + (16.0 * progress);

        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5 * opacity),
          ),
        );
      },
    );
  }
}
