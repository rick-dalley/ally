import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'patient.dart';
import 'pdf_report_builder.dart';
import 'provider.dart';

// Deliberately just a clearly-worded REQUEST, not a legal authorization — a valid
// release-of-information authorization has jurisdiction-specific requirements (consent
// language, an expiration date, sometimes a wet or verified signature) that this app
// isn't positioned to draft correctly for every office/province/state it might be
// handed to. Overclaiming legal force here would be worse than being plain about what
// this is: something to open the conversation with the office, not something that
// replaces their own authorization process.
class ReleaseOfInformationReport {
  static Future<Uint8List> build({
    required Patient patient,
    required Provider requestedFrom,
    required String whatIsRequested,
    String sendTo = "",
  }) async {
    final String recipient = sendTo.trim().isEmpty ? '${patient.firstName} ${patient.lastName} (myself)' : sendTo.trim();

    return ReportPdfBuilder.buildDocument(
      title: 'Request for Release of Information',
      build: () => [
        ReportPdfBuilder.patientHeader(patient),
        pw.Text('Request for Release of Information', style: ReportPdfBuilder.titleStyle.copyWith(fontSize: 16)),
        pw.SizedBox(height: 12),
        pw.Text(
          'This is a request from the patient, not a completed legal authorization. '
          'Please advise if your office requires its own release form or an in-person '
          'signature before this can be processed.',
          style: ReportPdfBuilder.helperStyle.copyWith(fontStyle: pw.FontStyle.italic),
        ),
        ReportPdfBuilder.sectionHeading('Requested From'),
        ReportPdfBuilder.keyValue('Provider', requestedFrom.fullName),
        if (requestedFrom.department != null && requestedFrom.department!.isNotEmpty)
          ReportPdfBuilder.keyValue('Department', requestedFrom.department!),
        ReportPdfBuilder.sectionHeading('What Is Being Requested'),
        pw.Text(whatIsRequested.trim().isEmpty ? 'Complete medical record.' : whatIsRequested.trim(), style: ReportPdfBuilder.bodyStyle),
        ReportPdfBuilder.sectionHeading('Send Results To'),
        pw.Text(recipient, style: ReportPdfBuilder.bodyStyle),
        pw.SizedBox(height: 40),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(height: 1, color: ReportPdfBuilder.borderSubtle),
                  pw.SizedBox(height: 4),
                  pw.Text('Patient Signature', style: ReportPdfBuilder.helperStyle),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(height: 1, color: ReportPdfBuilder.borderSubtle),
                  pw.SizedBox(height: 4),
                  pw.Text('Date', style: ReportPdfBuilder.helperStyle),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
