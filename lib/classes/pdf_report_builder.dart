import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'patient.dart';

// Shared layout for every generated report — a doctor's office should recognize these
// as coming from the same source at a glance. Print documents don't need full Carbon
// component parity (that's an in-app UI concern), but the accent color matches the real
// Carbon primary blue token rather than an arbitrary pick, for the same reason every
// other color choice this session traces back to carbon_color_constants.dart.
class ReportPdfBuilder {
  static const PdfColor accent = PdfColor.fromInt(0xFF0F62FE);
  static const PdfColor textPrimary = PdfColor.fromInt(0xFF161616);
  static const PdfColor textHelper = PdfColor.fromInt(0xFF6F6F6F);
  static const PdfColor borderSubtle = PdfColor.fromInt(0xFFE0E0E0);

  static final pw.TextStyle titleStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent);
  static final pw.TextStyle sectionStyle = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accent);
  static final pw.TextStyle bodyStyle = const pw.TextStyle(fontSize: 10, color: textPrimary);
  static final pw.TextStyle helperStyle = pw.TextStyle(fontSize: 9, color: textHelper);

  static String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  // Every report opens with who this is about and how to reach them — a doctor's
  // office receiving one of these cold needs that before anything else.
  static pw.Widget patientHeader(Patient patient) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${patient.firstName} ${patient.lastName}', style: titleStyle),
        pw.SizedBox(height: 4),
        pw.Text(
          'DOB: ${formatDate(patient.dob)}   Blood Type: ${patient.bloodType.label}',
          style: helperStyle,
        ),
        if (patient.phone.isNotEmpty) pw.Text('Phone: ${patient.phone}', style: helperStyle),
        pw.SizedBox(height: 12),
        pw.Divider(color: borderSubtle, thickness: 1),
      ],
    );
  }

  static pw.Widget sectionHeading(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Text(text.toUpperCase(), style: sectionStyle),
    );
  }

  static pw.Widget keyValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textPrimary)),
            pw.TextSpan(text: value, style: bodyStyle),
          ],
        ),
      ),
    );
  }

  static pw.Widget bulletList(List<String> items) {
    if (items.isEmpty) return pw.Text('None on file.', style: helperStyle);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items
          .map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('•  $item', style: bodyStyle),
              ))
          .toList(),
    );
  }

  static pw.Widget footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: borderSubtle, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated ${formatDate(DateTime.now())} — from the patient\'s own records', style: helperStyle),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: helperStyle),
          ],
        ),
      ],
    );
  }

  static Future<Uint8List> buildDocument({required String title, required List<pw.Widget> Function() build}) async {
    final pw.Document doc = pw.Document(title: title);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        footer: footer,
        build: (context) => build(),
      ),
    );
    return doc.save();
  }
}
