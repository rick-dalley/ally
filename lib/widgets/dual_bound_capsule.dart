import 'package:flutter/material.dart';

import 'high_low_close_capsule.dart';

// The top-panel dashboard's capsule — deliberately a separate widget from
// HighLowCloseCapsule (the per-card capsule, which only ever shows the Safe tier)
// rather than a fork-by-flag on that painter. The per-card capsule's geometry is
// proven and depended on already; this one has real extra structure (three nested
// bounds instead of one) that would have turned HlcCapsulePainter into a tangle of
// conditionals for a shape only the dashboard panel needs.
//
// Nesting, outside in: Safe (doctor-set, full capsule height) → Healthy (population
// guideline) → the patient's own historical min/max span → the current-reading dot.
// A reading inside Healthy is calm; outside Healthy but still inside Safe gets an
// in-place ripple halo (still visible on the pill, just a caution); outside Safe
// entirely floats the dot beyond the capsule's end with a red ripple halo, same
// "can't hide an out-of-bounds reading by clamping it back into the shape" principle
// HlcOutlierOverlay already established for the single-tier capsule.
class DualBoundCapsule extends StatelessWidget {
  final double current;
  final double historicalMin;
  final double historicalMax;
  final double healthyMin;
  final double healthyMax;
  final double safeMin;
  final double safeMax;
  final double height;
  final Color color;
  final Color warningColor;
  final Color alertColor;
  final Color inactiveColor;

  const DualBoundCapsule({
    super.key,
    required this.current,
    required this.historicalMin,
    required this.historicalMax,
    required this.healthyMin,
    required this.healthyMax,
    required this.safeMin,
    required this.safeMax,
    required this.height,
    required this.color,
    this.warningColor = Colors.orange,
    this.alertColor = Colors.red,
    this.inactiveColor = Colors.grey,
  });

  static const double _capsuleWidth = 16.0;
  static const double _margin = 16.0;

  double get _radius => _capsuleWidth / 2;
  double get _innerHeight => height - _capsuleWidth;
  double get _safeRange => safeMax - safeMin;

  // Same value-to-y mapping the painter uses, exposed here too so the ripple overlays
  // (built as ordinary positioned widgets, not canvas drawing) land exactly where the
  // painter drew the dot.
  double _yFor(double value) {
    if (_safeRange <= 0) return height / 2;
    final double normalized = (value - safeMin) / _safeRange;
    return _radius + (_innerHeight * (1.0 - normalized));
  }

  bool get _isInactive =>
      current == 0 && historicalMin == 0 && historicalMax == 0;
  bool get _isDanger =>
      !_isInactive && (current < safeMin || current > safeMax);
  bool get _isWarning =>
      !_isInactive &&
      !_isDanger &&
      (current < healthyMin || current > healthyMax);

  @override
  Widget build(BuildContext context) {
    final double totalHeight = height + (_margin * 2);
    final Color activeColor = _isInactive
        ? inactiveColor
        : (_isDanger ? alertColor : (_isWarning ? warningColor : color));

    return SizedBox(
      width: _capsuleWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: _margin,
            child: CustomPaint(
              size: Size(_capsuleWidth, height),
              painter: DualBoundCapsulePainter(
                current: current,
                historicalMin: historicalMin,
                historicalMax: historicalMax,
                healthyMin: healthyMin,
                healthyMax: healthyMax,
                safeMin: safeMin,
                safeMax: safeMax,
                color: activeColor,
                isInactive: _isInactive,
                isDanger: _isDanger,
              ),
            ),
          ),
          // In range but outside Healthy: the dot is drawn in its true (in-bounds)
          // position by the painter — this just adds the ripple halo at that same spot.
          if (_isWarning)
            Positioned(
              top: _margin + _yFor(current) - _radius,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: _capsuleWidth,
                  height: _capsuleWidth,
                  child: Center(child: HlcRippleEffect(color: warningColor)),
                ),
              ),
            ),
          // Outside Safe entirely: float the dot beyond the capsule's end, same
          // unconstrained-overlay approach as the single-tier capsule's outlier case.
          if (_isDanger)
            HlcOutlierOverlay(
              current: current,
              clinicalMin: safeMin,
              clinicalMax: safeMax,
              height: height,
              margin: _margin,
              capsuleWidth: _capsuleWidth,
              color: activeColor,
            ),
        ],
      ),
    );
  }
}

class DualBoundCapsulePainter extends CustomPainter {
  final double current;
  final double historicalMin;
  final double historicalMax;
  final double healthyMin;
  final double healthyMax;
  final double safeMin;
  final double safeMax;
  final Color color;
  final bool isInactive;
  final bool isDanger;

  DualBoundCapsulePainter({
    required this.current,
    required this.historicalMin,
    required this.historicalMax,
    required this.healthyMin,
    required this.healthyMax,
    required this.safeMin,
    required this.safeMax,
    required this.color,
    required this.isInactive,
    required this.isDanger,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    if (isInactive) {
      final RRect shell = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      );
      canvas.drawRRect(
        shell,
        Paint()
          ..color = color.withAlpha(80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      return;
    }

    final double innerHeight = size.height - size.width;
    final double safeRange = safeMax - safeMin;

    double getY(double val) {
      if (safeRange <= 0) return size.height / 2;
      final double normalized = (val - safeMin) / safeRange;
      return radius + (innerHeight * (1.0 - normalized));
    }

    RRect boundsRRect(double topY, double bottomY) {
      final double top = (topY < bottomY ? topY : bottomY) - radius;
      final double bottom = (topY > bottomY ? topY : bottomY) + radius;
      return RRect.fromRectAndRadius(
        Rect.fromLTRB(
          0,
          top.clamp(0, size.height),
          size.width,
          bottom.clamp(0, size.height),
        ),
        Radius.circular(radius),
      );
    }

    // 1. Outer capsule: Safe bounds, the full pill.
    final RRect safeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      safeRRect,
      Paint()
        ..color = color.withAlpha(15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      safeRRect,
      Paint()
        ..color = color.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2. Nested capsule: Healthy bounds, clamped inside the Safe pill.
    final double healthyTop = getY(
      healthyMax,
    ).clamp(radius, size.height - radius);
    final double healthyBottom = getY(
      healthyMin,
    ).clamp(radius, size.height - radius);
    canvas.drawRRect(
      boundsRRect(healthyTop, healthyBottom),
      Paint()
        ..color = color.withAlpha(45)
        ..style = PaintingStyle.fill,
    );

    // 3. Innermost: the patient's own historical min/max span, clamped inside Healthy.
    final double spanTop = getY(historicalMax).clamp(healthyTop, healthyBottom);
    final double spanBottom = getY(
      historicalMin,
    ).clamp(healthyTop, healthyBottom);
    if ((spanBottom - spanTop).abs() > 0) {
      canvas.drawRRect(
        boundsRRect(spanTop, spanBottom),
        Paint()
          ..color = color.withAlpha(100)
          ..style = PaintingStyle.fill,
      );
    }

    // 4. Current-reading dot — only drawn here while it's within the Safe pill; a
    // Safe-range outlier is handled entirely by the unconstrained floating overlay so
    // it can float past the capsule's physical end instead of being clamped into it.
    if (!isDanger) {
      final double yCurrent = getY(current).clamp(radius, size.height - radius);
      canvas.drawCircle(
        Offset(size.width / 2, yCurrent),
        radius * 0.7,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DualBoundCapsulePainter oldDelegate) {
    return oldDelegate.current != current ||
        oldDelegate.historicalMin != historicalMin ||
        oldDelegate.historicalMax != historicalMax ||
        oldDelegate.healthyMin != healthyMin ||
        oldDelegate.healthyMax != healthyMax ||
        oldDelegate.safeMin != safeMin ||
        oldDelegate.safeMax != safeMax ||
        oldDelegate.color != color ||
        oldDelegate.isInactive != isInactive ||
        oldDelegate.isDanger != isDanger;
  }
}
