import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'database_manager.dart';
import 'frequency_codes.dart';
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
  static Future<Uint8List> build({required Patient patient, required DateTime start, required DateTime end}) async {
    final List<Map<String, dynamic>> medicationRows = await DatabaseManager().getMedicationsActiveInRange(
      patient.patientUuid,
      start,
      end,
    );
    final List<Map<String, dynamic>> doseCounts = await DatabaseManager().getMedicationDoseCountsInRange(
      patient.patientUuid,
      start,
      end,
    );
    final Map<String, int> takenByMedication = {
      for (final row in doseCounts) row['medication_id'] as String: row['taken_count'] as int,
    };

    final List<Map<String, dynamic>> metricRows = await DatabaseManager().getMetricReadingsInRange(
      patient.patientUuid,
      start,
      end,
    );
    final List<Map<String, dynamic>> moodRows = await DatabaseManager().getMoodEntriesInRange(
      patient.patientUuid,
      start,
      end,
    );
    final List<Map<String, dynamic>> symptomRows = await DatabaseManager().getSymptomEntriesInRange(
      patient.patientUuid,
      start,
      end,
    );
    final List<Map<String, dynamic>> testRows = await DatabaseManager().getTestsCompletedInRange(
      patient.patientUuid,
      start,
      end,
    );
    final List<Map<String, dynamic>> diaryRows = await DatabaseManager().getDiaryEntriesInRange(
      patient.patientUuid,
      start,
      end,
    );

    final List<String> adherenceLines = medicationRows.map((row) {
      final String id = row['id'] as String;
      final String name = row['name'] as String;
      final int taken = takenByMedication[id] ?? 0;

      final DateTime medStart = DateTime.parse(row['started_taking'] as String).isAfter(start)
          ? DateTime.parse(row['started_taking'] as String)
          : start;
      final DateTime? stoppedRaw = row['stopped_taking'] != null ? DateTime.parse(row['stopped_taking'] as String) : null;
      final DateTime medEnd = (stoppedRaw != null && stoppedRaw.isBefore(end)) ? stoppedRaw : end;
      final int daysActive = medEnd.difference(medStart).inDays.clamp(1, 3650);

      final int dosesPerDay = FrequencySchedule.dailyTimesFor(row['freq'] as String?).length;
      if (dosesPerDay == 0) {
        return '$name — taken $taken time${taken == 1 ? '' : 's'} (as-needed, no fixed schedule to compare against)';
      }
      final int expected = dosesPerDay * daysActive;
      final int pct = expected > 0 ? ((taken / expected) * 100).clamp(0, 100).round() : 0;
      return '$name — $pct% ($taken of $expected expected doses)';
    }).toList();

    final List<String> metricLines = metricRows.map((row) {
      final double value = (row['value'] as num).toDouble();
      final double? safeLow = (row['safe_lower_limit'] as num?)?.toDouble();
      final double? safeHigh = (row['safe_upper_limit'] as num?)?.toDouble();
      final bool outOfSafeRange = (safeLow != null && value < safeLow) || (safeHigh != null && value > safeHigh);
      final String date = ReportPdfBuilder.formatDate(DateTime.parse(row['measured'] as String));
      final String flag = outOfSafeRange ? '  [outside safe range]' : '';
      return '$date — ${row['metric_name']}: $value ${row['unit_of_measure']}$flag';
    }).toList();

    final List<String> moodLines = moodRows.map((row) {
      final Sentiment mood = Sentiment.values[row['mood'] as int];
      final String date = ReportPdfBuilder.formatDate(DateTime.parse(row['start_date'] as String));
      final String reason = (row['reason'] as String?) ?? '';
      return '$date — ${mood.label}${reason.isNotEmpty ? ' ($reason)' : ''}';
    }).toList();

    final List<String> symptomLines = symptomRows.map((row) {
      final DateTime recorded = DateTime.fromMillisecondsSinceEpoch((row['recorded'] as int) * 1000);
      final int? severityIndex = row['severity'] as int?;
      final String severity = severityIndex != null ? DetailedPainLevel.values[severityIndex].label : '';
      return '${ReportPdfBuilder.formatDate(recorded)} — ${row['zone_name']}${severity.isNotEmpty ? ' ($severity)' : ''}';
    }).toList();

    final List<String> testLines = testRows.map((row) {
      final String date = ReportPdfBuilder.formatDate(DateTime.parse(row['completed_on'] as String));
      return '$date — ${row['name']}';
    }).toList();

    final List<String> diaryLines = diaryRows.map((row) {
      final String date = row['entry_date'] as String;
      return '$date: ${row['content']}';
    }).toList();

    return ReportPdfBuilder.buildDocument(
      title: 'Progress Report',
      build: () => [
        ReportPdfBuilder.patientHeader(patient),
        pw.Text('Progress Report', style: ReportPdfBuilder.titleStyle.copyWith(fontSize: 16)),
        pw.SizedBox(height: 4),
        pw.Text(
          '${ReportPdfBuilder.formatDate(start)} to ${ReportPdfBuilder.formatDate(end)}',
          style: ReportPdfBuilder.helperStyle,
        ),
        ReportPdfBuilder.sectionHeading('Medication Adherence'),
        ReportPdfBuilder.bulletList(adherenceLines),
        ReportPdfBuilder.sectionHeading('Metric Readings'),
        ReportPdfBuilder.bulletList(metricLines),
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
