import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/metric_value.dart';
import '../classes/patient.dart';
import 'body_metrics_entry_widget.dart';

class BodyMetricsWidget extends StatefulWidget {
  final Patient patient;
  const BodyMetricsWidget({super.key, required this.patient});

  @override
  State<StatefulWidget> createState() => BodyMetricsWidgetState();
}

class BodyMetricsWidgetState extends State<BodyMetricsWidget> {
  @override
  Widget build(BuildContext context) {
    final double currentHeight = widget.patient.height;
    final double currentWeight = widget.patient.weight;
    final String currentHeightUoM = widget.patient.heightUoM;
    final String currentWeightUoM = widget.patient.weightUoM;

    final heightStr = '${currentHeight.toStringAsFixed(1)} $currentHeightUoM';
    final weightStr = '${currentWeight.toStringAsFixed(1)} $currentWeightUoM';
    final bmiValue = MedicalMath.calculateBMI(
      weight: currentWeight,
      weightUom: currentWeightUoM,
      height: currentHeight,
      heightUom: currentHeightUoM,
    );
    final bmiStr = bmiValue > 0 ? bmiValue.toStringAsFixed(1) : 'Not Set';

    return InkWell(
      onTap: () {
        _showMetricsEntryDialog(
          context: context,
          initialHeight: currentHeight,
          initialHeightUom: currentHeightUoM,
          initialWeight: currentWeight,
          initialWeightUom: currentWeightUoM,
        );
      },
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            // 1. HEIGHT COLUMN (Occupies exactly 1/3 of available row space)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HEIGHT', // Pro-tip: Shortening labels to HT/WT saves massive real estate on small screens
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      heightStr,
                      style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis, // Prevents layout explosion if string is long
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4), // Small safe gutter padding
            // 2. WEIGHT COLUMN (Occupies exactly 1/3 of available row space)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WEIGHT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      weightStr,
                      style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // 3. BMI COLUMN (Occupies exactly 1/3 of available row space)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BMI',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      bmiStr,
                      style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            // 4. FIXED ICON ANCHOR
            Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void onMetricsChanged({double? newHeight, double? newWeight, required Patient patient}) async {
    final String patientUuid = patient.patientUuid;
    if (patientUuid.isEmpty) return;

    if (newHeight != null && newHeight > 0) {
      final MetricValue? lastHeightMetric = await DatabaseManager().getLatestMetric(patientUuid, 'height');

      if (lastHeightMetric == null || lastHeightMetric.value != newHeight) {
        await DatabaseManager().insertPatientMetric(patientUuid, newHeight, 'height');
        setState(() {
          patient.height = newHeight;
        });
      }
    }

    // --- HANDLE WEIGHT FILTER ---
    if (newWeight != null && newWeight > 0) {
      final MetricValue? lastWeightMetric = await DatabaseManager().getLatestMetric(patientUuid, 'weight');
      bool shouldWriteWeight = true;

      if (lastWeightMetric != null) {
        final Duration timeSinceLastLog = DateTime.now().difference(lastWeightMetric.recorded);
        if (lastWeightMetric.value == newWeight && timeSinceLastLog.inHours < 23) {
          shouldWriteWeight = false;
        }
      }

      if (shouldWriteWeight) {
        await DatabaseManager().insertPatientMetric(patientUuid, newWeight, 'weight');
        setState(() {
          patient.weight = newWeight;
        });
      }
    }
  }

  void _showMetricsEntryDialog({
    required BuildContext context,
    double? initialHeight,
    required String initialHeightUom,
    double? initialWeight,
    required String initialWeightUom,
  }) {
    final double? cleanHeight = (initialHeight == 0.0) ? null : initialHeight;
    final double? cleanWeight = (initialWeight == 0.0) ? null : initialWeight;
    final String normalizedHeightUom = initialHeightUom.toLowerCase();
    final String normalizedWeightUom = initialWeightUom.toLowerCase();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Patient Metrics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
          ),
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BodyMetricsEntryWidget(
                  height: cleanHeight,
                  weight: cleanWeight,
                  heightUom: normalizedHeightUom,
                  weightUom: normalizedWeightUom,
                  onMetricsChanged: (newWeightValue, newHeightValue) {
                    //Pop the UI instantly so the app feels snappy
                    Navigator.pop(dialogContext);
                    Future.microtask(() {
                      onMetricsChanged(newWeight: newWeightValue, newHeight: newHeightValue, patient: widget.patient);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
