import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'allergen.dart';
import 'database_manager.dart';
import 'patient.dart';
import 'patient_condition.dart';
import 'patient_pain.dart';
import 'pdf_report_builder.dart';

// A new doctor's first look at this patient — full condition history (not just active,
// unlike the Emergency QR's fast-triage scope), current medications, allergies, and
// whatever's currently bothering the patient, plus room for the patient to add anything
// in their own words before it goes out.
class LetterOfIntroductionReport {
  static Future<Uint8List> build({required Patient patient, String additionalNotes = ""}) async {
    final List<Map<String, dynamic>> conditionRows = await DatabaseManager().getConditionHistoryRows(
      patient.patientUuid,
    );
    final List<Map<String, dynamic>> medicationRows = await DatabaseManager().getActiveMedicationRows(
      patient.patientUuid,
    );
    final List<Map<String, dynamic>> allergyRows = await DatabaseManager().getAllergyDetailRows(patient.patientUuid);
    final List<Map<String, dynamic>> symptomRows = await DatabaseManager().getActiveSymptomRows(patient.patientUuid);

    final List<String> conditionLines = conditionRows.map((row) {
      final ConditionStatus status = ConditionStatus.values[row['status'] as int? ?? 0];
      final String onset = row['onset'] != null ? ReportPdfBuilder.formatDate(DateTime.parse(row['onset'] as String)) : 'date unknown';
      return '${row['name']} — ${status.label}, since $onset';
    }).toList();

    final List<String> medicationLines = medicationRows.map((row) {
      final String dose = (row['dose'] as String?) ?? '';
      final String freq = (row['freq'] as String?) ?? '';
      return '${row['name']}${dose.isNotEmpty ? ' — $dose' : ''}${freq.isNotEmpty ? ', $freq' : ''}';
    }).toList();

    final List<String> allergyLines = allergyRows.map((row) {
      final AllergySeverity severity = AllergySeverity.values[row['severity'] as int? ?? 0];
      final String reaction = (row['reaction'] as String?) ?? '';
      return '${row['name']} — ${severity.label}${reaction.isNotEmpty ? ' ($reaction)' : ''}';
    }).toList();

    final List<String> concernLines = symptomRows.map((row) {
      final int? severityIndex = row['severity'] as int?;
      final int? frequencyIndex = row['frequency'] as int?;
      final String severity = severityIndex != null ? DetailedPainLevel.values[severityIndex].label : '';
      final String frequency = frequencyIndex != null ? Frequency.values[frequencyIndex].label : '';
      final String descriptor = [severity, frequency].where((s) => s.isNotEmpty).join(', ');
      return '${row['zone_name']}${descriptor.isNotEmpty ? ' — $descriptor' : ''}';
    }).toList();

    return ReportPdfBuilder.buildDocument(
      title: 'Letter of Introduction',
      build: () => [
        ReportPdfBuilder.patientHeader(patient),
        pw.Text('Letter of Introduction', style: ReportPdfBuilder.titleStyle.copyWith(fontSize: 16)),
        pw.SizedBox(height: 4),
        pw.Text(
          'This summary was assembled from ${patient.firstName}\'s own health records, kept on their phone.',
          style: ReportPdfBuilder.helperStyle,
        ),
        ReportPdfBuilder.sectionHeading('Current Concerns'),
        ReportPdfBuilder.bulletList(concernLines),
        ReportPdfBuilder.sectionHeading('Current Medications'),
        ReportPdfBuilder.bulletList(medicationLines),
        ReportPdfBuilder.sectionHeading('Allergies'),
        ReportPdfBuilder.bulletList(allergyLines),
        ReportPdfBuilder.sectionHeading('Medical History'),
        ReportPdfBuilder.bulletList(conditionLines),
        if (additionalNotes.trim().isNotEmpty) ...[
          ReportPdfBuilder.sectionHeading('From the Patient'),
          pw.Text(additionalNotes.trim(), style: ReportPdfBuilder.bodyStyle),
        ],
      ],
    );
  }
}
