import 'package:flutter/material.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import 'carbon_segmented_control.dart';

enum ChartRange { day, week, month, year }

extension ChartRangeSpan on ChartRange {
  Duration get lookback {
    switch (this) {
      case ChartRange.day:
        return const Duration(days: 1);
      case ChartRange.week:
        return const Duration(days: 7);
      case ChartRange.month:
        return const Duration(days: 30);
      case ChartRange.year:
        return const Duration(days: 365);
    }
  }

  String get label {
    switch (this) {
      case ChartRange.day:
        return "D";
      case ChartRange.week:
        return "W";
      case ChartRange.month:
        return "M";
      case ChartRange.year:
        return "Y";
    }
  }
}

class _ScatterPoint {
  final DateTime time;
  final double value;
  const _ScatterPoint(this.time, this.value);
}

// The metric card's real trend chart, replacing the "coming soon" placeholder. A plain
// dot-per-reading scatter deliberately, not a trend line — Richard's own framing is that
// a fitted line means something once there's enough data density to fit, and until then
// it would just be inventing a shape that isn't really there. The D/W/M/Y switcher is the
// only interaction; simple and clean over feature-complete.
class MetricScatterChart extends StatefulWidget {
  final List<Map<String, dynamic>> historicalValues;
  final Color color;
  // All optional and independent — a metric might have a target but no custom safe
  // bounds, or vice versa. Null just means that reference line isn't drawn.
  final double? safeMin;
  final double? safeMax;
  final double? healthyMin;
  final double? healthyMax;
  final double? targetValue;

  const MetricScatterChart({
    super.key,
    required this.historicalValues,
    required this.color,
    this.safeMin,
    this.safeMax,
    this.healthyMin,
    this.healthyMax,
    this.targetValue,
  });

  @override
  State<MetricScatterChart> createState() => _MetricScatterChartState();
}

class _MetricScatterChartState extends State<MetricScatterChart> {
  ChartRange range = ChartRange.week;

  List<_ScatterPoint> _pointsFor(DateTime start, DateTime end) {
    final List<_ScatterPoint> points = [];
    for (final row in widget.historicalValues) {
      final num? rawValue = (row['metric_value'] ?? row['value']) as num?;
      final dynamic rawDate = row['recorded_at'] ?? row['recorded'];
      final DateTime? recorded = rawDate == null
          ? null
          : DateTime.tryParse(rawDate.toString());
      if (rawValue == null || recorded == null) continue;
      if (recorded.isBefore(start) || recorded.isAfter(end)) continue;
      points.add(_ScatterPoint(recorded, rawValue.toDouble()));
    }
    points.sort((a, b) => a.time.compareTo(b.time));
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime end = DateTime.now();
    final DateTime start = end.subtract(range.lookback);
    final List<_ScatterPoint> points = _pointsFor(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarbonSegmentedControl<ChartRange>(
          options: ChartRange.values,
          value: range,
          labelBuilder: (r) => r.label,
          onChanged: (r) => setState(() => range = r),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 12, 12, 4),
          decoration: BoxDecoration(
            color: CarbonTheme.getTileColor(CarbonTileStyle.base),
            border: Border.all(color: carbonColorBorderSubtle03),
          ),
          child: points.isEmpty
              ? Center(
                  child: Text(
                    "No readings in this range",
                    style: CarbonTheme.carbonTextStyle,
                  ),
                )
              : CustomPaint(
                  size: Size.infinite,
                  painter: _ScatterPainter(
                    points: points,
                    rangeStart: start,
                    rangeEnd: end,
                    color: widget.color,
                    safeMin: widget.safeMin,
                    safeMax: widget.safeMax,
                    healthyMin: widget.healthyMin,
                    healthyMax: widget.healthyMax,
                    targetValue: widget.targetValue,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<_ScatterPoint> points;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Color color;
  final double? safeMin;
  final double? safeMax;
  final double? healthyMin;
  final double? healthyMax;
  final double? targetValue;

  _ScatterPainter({
    required this.points,
    required this.rangeStart,
    required this.rangeEnd,
    required this.color,
    this.safeMin,
    this.safeMax,
    this.healthyMin,
    this.healthyMax,
    this.targetValue,
  });

  static const double _leftPadding = 40;
  static const double _bottomPadding = 18;
  static const double _topPadding = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final double plotLeft = _leftPadding;
    final double plotRight = size.width;
    final double plotTop = _topPadding;
    final double plotBottom = size.height - _bottomPadding;
    if (plotRight <= plotLeft || plotBottom <= plotTop) return;

    double valueMin = points
        .map((p) => p.value)
        .reduce((a, b) => a < b ? a : b);
    double valueMax = points
        .map((p) => p.value)
        .reduce((a, b) => a > b ? a : b);
    // Fold every reference line into the axis range too — a Safe bound the readings
    // never get close to should still be visible on the chart, not clipped off just
    // because the actual data happens to sit well inside it.
    for (final bound in [
      safeMin,
      safeMax,
      healthyMin,
      healthyMax,
      targetValue,
    ]) {
      if (bound == null) continue;
      if (bound < valueMin) valueMin = bound;
      if (bound > valueMax) valueMax = bound;
    }
    if (valueMax == valueMin) {
      // A flat line of identical readings still needs vertical room to plot in, not a
      // zero-height range that collapses every dot onto the same pixel.
      valueMin -= 1;
      valueMax += 1;
    } else {
      final double pad = (valueMax - valueMin) * 0.1;
      valueMin -= pad;
      valueMax += pad;
    }

    final double timeRange = rangeEnd
        .difference(rangeStart)
        .inMilliseconds
        .toDouble();

    double xFor(DateTime t) {
      if (timeRange <= 0) return plotLeft;
      final double frac = t.difference(rangeStart).inMilliseconds / timeRange;
      return plotLeft + frac.clamp(0.0, 1.0) * (plotRight - plotLeft);
    }

    double yFor(double v) {
      final double frac = (v - valueMin) / (valueMax - valueMin);
      return plotBottom - frac.clamp(0.0, 1.0) * (plotBottom - plotTop);
    }

    final Paint axisPaint = Paint()
      ..color = carbonColorBorderStrong03
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(plotLeft, plotTop),
      Offset(plotLeft, plotBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(plotLeft, plotBottom),
      Offset(plotRight, plotBottom),
      axisPaint,
    );

    // Manual dash stepping — Canvas has no built-in dashed-stroke primitive.
    void drawDashedHLine(double y, Color lineColor) {
      const double dashWidth = 4;
      const double dashGap = 3;
      final Paint dashPaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.0;
      double x = plotLeft;
      while (x < plotRight) {
        final double segmentEnd = (x + dashWidth).clamp(plotLeft, plotRight);
        canvas.drawLine(Offset(x, y), Offset(segmentEnd, y), dashPaint);
        x += dashWidth + dashGap;
      }
    }

    // Safe/Healthy each draw as a pair of bounds when both are known; Target is a
    // single line. Colors match the semantics already established for DualBoundCapsule
    // — red for Safe, amber for Healthy — so the same color always means the same
    // thing across the dashboard panel and this chart.
    if (safeMin != null)
      drawDashedHLine(yFor(safeMin!), carbonColorSupportError);
    if (safeMax != null)
      drawDashedHLine(yFor(safeMax!), carbonColorSupportError);
    if (healthyMin != null)
      drawDashedHLine(yFor(healthyMin!), carbonColorSupportWarning);
    if (healthyMax != null)
      drawDashedHLine(yFor(healthyMax!), carbonColorSupportWarning);
    if (targetValue != null)
      drawDashedHLine(yFor(targetValue!), carbonColorSupportSuccess);

    void drawLabel(
      String text,
      Offset topLeft, {
      TextAlign align = TextAlign.left,
    }) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: text, style: CarbonTheme.carbonHelperTextStyle),
        textAlign: align,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(canvas, topLeft);
    }

    drawLabel(valueMax.toStringAsFixed(1), const Offset(0, _topPadding - 4));
    drawLabel(valueMin.toStringAsFixed(1), Offset(0, plotBottom - 12));

    String shortDate(DateTime d) => "${d.month}/${d.day}";
    drawLabel(shortDate(rangeStart), Offset(plotLeft, plotBottom + 2));
    final String endLabel = shortDate(rangeEnd);
    drawLabel(
      endLabel,
      Offset(plotRight - (endLabel.length * 7.0), plotBottom + 2),
    );

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(
        Offset(xFor(point.time), yFor(point.value)),
        3.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.rangeStart != rangeStart ||
        oldDelegate.rangeEnd != rangeEnd ||
        oldDelegate.color != color ||
        oldDelegate.safeMin != safeMin ||
        oldDelegate.safeMax != safeMax ||
        oldDelegate.healthyMin != healthyMin ||
        oldDelegate.healthyMax != healthyMax ||
        oldDelegate.targetValue != targetValue;
  }
}
