import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'database_manager.dart';
import 'frequency_codes.dart';
import 'metric_value.dart';
import 'patient.dart';
import 'patient_pain.dart';
import 'patient_sentiment.dart';
import 'pdf_report_builder.dart';

// "What's happened since my last appointment" — the patient picks how far back to go
// (see ReportPdfBuilder for why: only the patient/doctor can judge that, not the app).
// Adherence is computed from real observed 'taken' doses against an expected count
// derived from the medication's own frequency schedule — not self-reported, not
// guessed.
class TherapyPeriodReport {
  static Future<Uint8List> build({
    required Patient patient,
    required DateTime start,
    required DateTime end,
  }) async {
    final List<Map<String, dynamic>> medicationRows = await DatabaseManager()
        .getMedicationsActiveInRange(patient.patientUuid, start, end);
    final List<Map<String, dynamic>> doseCounts = await DatabaseManager()
        .getMedicationDoseCountsInRange(patient.patientUuid, start, end);
    final Map<String, int> takenByMedication = {
      for (final row in doseCounts)
        row['medication_id'] as String: row['taken_count'] as int,
    };

    final List<Map<String, dynamic>> metricRows = await DatabaseManager()
        .getMetricReadingsInRange(patient.patientUuid, start, end);
    final List<Map<String, dynamic>> thresholdRows = await DatabaseManager()
        .getActiveThresholds(patient.patientUuid);
    final List<Map<String, dynamic>> targetRows = await DatabaseManager()
        .getActiveTargets(patient.patientUuid);
    final Map<int, MetricThreshold> thresholdByMetric = {
      for (final row in thresholdRows)
        row['metric_id'] as int: MetricThreshold.fromMap(row),
    };
    final Map<int, MetricTarget> targetByMetric = {
      for (final row in targetRows)
        row['metric_id'] as int: MetricTarget.fromMap(row),
    };
    final List<Map<String, dynamic>> moodRows = await DatabaseManager()
        .getMoodEntriesInRange(patient.patientUuid, start, end);
    final List<Map<String, dynamic>> symptomRows = await DatabaseManager()
        .getSymptomEntriesInRange(patient.patientUuid, start, end);
    final List<Map<String, dynamic>> testRows = await DatabaseManager()
        .getTestsCompletedInRange(patient.patientUuid, start, end);
    final List<Map<String, dynamic>> diaryRows = await DatabaseManager()
        .getDiaryEntriesInRange(patient.patientUuid, start, end);

    final List<String> adherenceLines = medicationRows.map((row) {
      final String id = row['id'] as String;
      final String name = row['name'] as String;
      final int taken = takenByMedication[id] ?? 0;

      final DateTime medStart =
          DateTime.parse(row['started_taking'] as String).isAfter(start)
          ? DateTime.parse(row['started_taking'] as String)
          : start;
      final DateTime? stoppedRaw = row['stopped_taking'] != null
          ? DateTime.parse(row['stopped_taking'] as String)
          : null;
      final DateTime medEnd = (stoppedRaw != null && stoppedRaw.isBefore(end))
          ? stoppedRaw
          : end;
      final int daysActive = medEnd.difference(medStart).inDays.clamp(1, 3650);

      final int dosesPerDay = FrequencySchedule.dailyTimesFor(
        row['freq'] as String?,
      ).length;
      if (dosesPerDay == 0) {
        return '$name - taken $taken time${taken == 1 ? '' : 's'} (as-needed, no fixed schedule to compare against)';
      }
      final int expected = dosesPerDay * daysActive;
      final int pct = expected > 0
          ? ((taken / expected) * 100).clamp(0, 100).round()
          : 0;
      return '$name - $pct% ($taken of $expected expected doses)';
    }).toList();

    // Grouped by metric so each gets its own trend chart rather than a flat dump of
    // every reading — a doctor scanning this wants the shape of "how has this metric
    // moved", not a transcription of the raw log (that's what the app itself is for).
    final Map<int, String> metricNames = {};
    final Map<int, String> metricUnits = {};
    final Map<int, double?> safeLowByMetric = {};
    final Map<int, double?> safeHighByMetric = {};
    final Map<int, double?> healthyLowByMetric = {};
    final Map<int, double?> healthyHighByMetric = {};
    final Map<int, List<MapEntry<DateTime, double>>> readingsByMetric = {};
    for (final row in metricRows) {
      final int metricId = row['metric_id'] as int;
      metricNames[metricId] = row['metric_name'] as String;
      metricUnits[metricId] = (row['unit_of_measure'] as String?) ?? '';
      safeLowByMetric[metricId] = (row['safe_lower_limit'] as num?)?.toDouble();
      safeHighByMetric[metricId] = (row['safe_upper_limit'] as num?)
          ?.toDouble();
      healthyLowByMetric[metricId] = (row['healthy_lower_limit'] as num?)
          ?.toDouble();
      healthyHighByMetric[metricId] = (row['healthy_upper_limit'] as num?)
          ?.toDouble();
      readingsByMetric
          .putIfAbsent(metricId, () => [])
          .add(
            MapEntry(
              DateTime.parse(row['measured'] as String),
              (row['value'] as num).toDouble(),
            ),
          );
    }

    final List<pw.Widget> metricTrendWidgets = [];
    for (final metricId in readingsByMetric.keys) {
      final List<MapEntry<DateTime, double>> readings =
          readingsByMetric[metricId]!;
      final String unit = metricUnits[metricId] ?? '';
      final MetricThreshold? threshold = thresholdByMetric[metricId];
      final MetricTarget? target = targetByMetric[metricId];
      final double latestValue = readings.last.value;
      final double minValue = readings
          .map((e) => e.value)
          .reduce((a, b) => a < b ? a : b);
      final double maxValue = readings
          .map((e) => e.value)
          .reduce((a, b) => a > b ? a : b);

      metricTrendWidgets.addAll([
        pw.Text(
          unit.isNotEmpty
              ? '${metricNames[metricId]} ($unit)'
              : metricNames[metricId]!,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: ReportPdfBuilder.textPrimary,
          ),
        ),
        pw.SizedBox(height: 4),
        ReportPdfBuilder.trendChart(
          points: readings,
          safeMin: threshold?.dangerLow ?? safeLowByMetric[metricId],
          safeMax: threshold?.dangerHigh ?? safeHighByMetric[metricId],
          healthyMin: threshold?.healthyLow ?? healthyLowByMetric[metricId],
          healthyMax: threshold?.healthyHigh ?? healthyHighByMetric[metricId],
          targetValue: target?.targetValue,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Latest: ${latestValue.toStringAsFixed(1)}   Range: ${minValue.toStringAsFixed(1)}–${maxValue.toStringAsFixed(1)} over ${readings.length} reading${readings.length == 1 ? '' : 's'}',
          style: ReportPdfBuilder.helperStyle,
        ),
        pw.SizedBox(height: 12),
      ]);
    }

    final List<String> moodLines = moodRows.map((row) {
      final Sentiment mood = Sentiment.values[row['mood'] as int];
      final String date = ReportPdfBuilder.formatDate(
        DateTime.parse(row['start_date'] as String),
      );
      final String reason = (row['reason'] as String?) ?? '';
      return '$date - ${mood.label}${reason.isNotEmpty ? ' ($reason)' : ''}';
    }).toList();

    final List<String> symptomLines = symptomRows.map((row) {
      final DateTime recorded = DateTime.fromMillisecondsSinceEpoch(
        (row['recorded'] as int) * 1000,
      );
      final int? severityIndex = row['severity'] as int?;
      final String severity = severityIndex != null
          ? DetailedPainLevel.values[severityIndex].label
          : '';
      return '${ReportPdfBuilder.formatDate(recorded)} - ${row['zone_name']}${severity.isNotEmpty ? ' ($severity)' : ''}';
    }).toList();

    final List<String> testLines = testRows.map((row) {
      final String date = ReportPdfBuilder.formatDate(
        DateTime.parse(row['completed_on'] as String),
      );
      return '$date - ${row['name']}';
    }).toList();

    final List<String> diaryLines = diaryRows.map((row) {
      final String date = row['entry_date'] as String;
      return '$date: ${row['content']}';
    }).toList();

    return ReportPdfBuilder.buildDocument(
      title: 'Progress Report',
      build: () => [
        ReportPdfBuilder.patientHeader(patient),
        pw.Text(
          'Progress Report',
          style: ReportPdfBuilder.titleStyle.copyWith(fontSize: 16),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${ReportPdfBuilder.formatDate(start)} to ${ReportPdfBuilder.formatDate(end)}',
          style: ReportPdfBuilder.helperStyle,
        ),
        ReportPdfBuilder.sectionHeading('Medication Adherence'),
        ReportPdfBuilder.bulletList(adherenceLines),
        ReportPdfBuilder.sectionHeading('Metric Trends'),
        if (metricTrendWidgets.isEmpty)
          pw.Text('None on file.', style: ReportPdfBuilder.helperStyle)
        else
          ...metricTrendWidgets,
        ReportPdfBuilder.sectionHeading('Mood'),
        ReportPdfBuilder.bulletList(moodLines),
        ReportPdfBuilder.sectionHeading('Symptoms Logged'),
        ReportPdfBuilder.bulletList(symptomLines),
        ReportPdfBuilder.sectionHeading('Tests Completed'),
        ReportPdfBuilder.bulletList(testLines),
        ReportPdfBuilder.sectionHeading('Patient Observations'),
        ReportPdfBuilder.bulletList(diaryLines),
      ],
    );
  }
}
