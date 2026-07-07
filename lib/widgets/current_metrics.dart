import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/vertical_range_indicator.dart';
import '../classes/vitals.dart';

class CurrentMetrics extends StatelessWidget {
  final String title;
  final CurrentVitalsRecord? vitals;
  final double barHeight;
  final VoidCallback? onTap;

  const CurrentMetrics({super.key, required this.title, required this.vitals, this.barHeight = 80.0, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Adding 30px to account for the label height to prevent overflow
    const double labelBuffer = 30.0;
    final double totalHeight = barHeight + labelBuffer;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              SizedBox(
                height: totalHeight,
                child: Row(
                  children:
                      vitals?.mapValues.entries.map((entry) {
                        final MetricType type = entry.key;
                        final MetricInstance data = entry.value;
                        final Limits limits = vitalsLimits[type]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: VerticalRangeIndicator(
                            height: barHeight,
                            current: data.current,
                            min: data.min,
                            max: data.max,
                            clinicalMin: limits.lower,
                            clinicalMax: limits.upper,
                            label: (metricDisplayLabels[type] ?? "val").toUpperCase(),
                            color: _getColorForType(type),
                          ),
                        );
                      }).toList() ??
                      [],
                ),
              ),
              Positioned(
                right: 0,
                bottom: labelBuffer / 2, // Centers arrow vertically relative to the bars
                child: const Icon(Symbols.arrow_forward, size: 24, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForType(MetricType type) {
    switch (type) {
      case MetricType.systolic:
        return Colors.blue;
      case MetricType.diastolic:
        return Colors.blueGrey;
      case MetricType.pulse:
        return Colors.purple;
      case MetricType.spo2:
        return Colors.green;
      case MetricType.temperature:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
