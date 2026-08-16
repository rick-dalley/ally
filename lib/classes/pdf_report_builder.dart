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
  // Same semantics as the in-app scatter chart's dashed reference lines (and
  // carbon_color_constants.dart's carbonColorSupportError/Warning/Success) — red for
  // Safe, amber for Healthy, green for Target — so a doctor flipping between the app
  // and the printed report sees the same color mean the same thing.
  static const PdfColor safeLineColor = PdfColor.fromInt(0xFFda1e28);
  static const PdfColor healthyLineColor = PdfColor.fromInt(0xFFf1c21b);
  static const PdfColor targetLineColor = PdfColor.fromInt(0xFF24a148);

  // CWICare wordmark colors — "CWI" in purple, "are" in peacock blue, with the
  // connecting "C" as a blend of the two so the word reads as one continuous gradient
  // rather than two flatly-colored halves stitched together.
  static const PdfColor brandPurple = PdfColor.fromInt(0xFF6929C4);
  static const PdfColor brandPeacock = PdfColor.fromInt(0xFF1CA9C9);
  static const PdfColor brandBlend = PdfColor.fromInt(0xFF4369C7);

  static final pw.TextStyle titleStyle = pw.TextStyle(
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
    color: accent,
  );
  static final pw.TextStyle sectionStyle = pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: accent,
  );
  static final pw.TextStyle bodyStyle = const pw.TextStyle(
    fontSize: 10,
    color: textPrimary,
  );
  static final pw.TextStyle helperStyle = pw.TextStyle(
    fontSize: 9,
    color: textHelper,
  );

  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  // The CWICare wordmark, letter by letter: C-W-I in purple, the connecting C blended,
  // "are" in peacock blue. Used as the masthead above every report and nowhere else —
  // at footer size this treatment would just be noise, so the footer stays plain.
  static pw.Widget brandWordmark({double fontSize = 20}) {
    final pw.TextStyle base = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: 'CWI',
            style: base.copyWith(color: brandPurple),
          ),
          pw.TextSpan(
            text: 'C',
            style: base.copyWith(color: brandBlend),
          ),
          pw.TextSpan(
            text: 'are',
            style: base.copyWith(color: brandPeacock),
          ),
        ],
      ),
    );
  }

  // Every report opens with the CWICare masthead, then who this is about and how to
  // reach them — a doctor's office receiving one of these cold needs both before
  // anything else.
  static pw.Widget patientHeader(Patient patient) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            brandWordmark(),
            pw.SizedBox(width: 6),
            pw.Text(
              'Patient Report',
              style: pw.TextStyle(fontSize: 20, color: textPrimary),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('${patient.firstName} ${patient.lastName}', style: titleStyle),
        pw.SizedBox(height: 4),
        pw.Text(
          'DOB: ${formatDate(patient.dob)}   Blood Type: ${patient.bloodType.label}',
          style: helperStyle,
        ),
        if (patient.phone.isNotEmpty)
          pw.Text('Phone: ${patient.phone}', style: helperStyle),
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
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: textPrimary,
              ),
            ),
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
          .map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text('•  $item', style: bodyStyle),
            ),
          )
          .toList(),
    );
  }

  static const double _chartHeight = 100;

  // A dot-per-reading trend chart for a report period, deliberately the same visual
  // language as MetricScatterChart in the app (plain dots, not a fitted line — a report
  // spanning a few readings shouldn't imply a trend shape that isn't really there) with
  // the same Safe/Healthy/Target dashed reference lines, so what the doctor sees on
  // paper matches what the patient sees on the card.
  static pw.Widget trendChart({
    required List<MapEntry<DateTime, double>> points,
    double? safeMin,
    double? safeMax,
    double? healthyMin,
    double? healthyMax,
    double? targetValue,
  }) {
    if (points.isEmpty)
      return pw.Text('No readings in this period.', style: helperStyle);

    final List<MapEntry<DateTime, double>> sorted = List.of(points)
      ..sort((a, b) => a.key.compareTo(b.key));
    final DateTime start = sorted.first.key;
    final DateTime end = sorted.last.key;

    double valueMin = sorted
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    double valueMax = sorted
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
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
      valueMin -= 1;
      valueMax += 1;
    } else {
      final double pad = (valueMax - valueMin) * 0.1;
      valueMin -= pad;
      valueMax += pad;
    }
    final double plotValueMin = valueMin;
    final double plotValueMax = valueMax;
    final double timeRange = end.difference(start).inMilliseconds.toDouble();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 32,
          height: _chartHeight,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(plotValueMax.toStringAsFixed(1), style: helperStyle),
              pw.Text(plotValueMin.toStringAsFixed(1), style: helperStyle),
            ],
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                height: _chartHeight,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderSubtle, width: 0.5),
                ),
                child: pw.CustomPaint(
                  size: const PdfPoint(double.infinity, _chartHeight),
                  painter: (canvas, size) {
                    const double margin = 6;
                    final double plotLeft = margin;
                    final double plotRight = size.x - margin;
                    final double plotBottom = margin;
                    final double plotTop = size.y - margin;
                    if (plotRight <= plotLeft || plotTop <= plotBottom) return;

                    double xFor(DateTime t) {
                      if (timeRange <= 0) return (plotLeft + plotRight) / 2;
                      final double frac =
                          t.difference(start).inMilliseconds / timeRange;
                      return plotLeft +
                          frac.clamp(0.0, 1.0) * (plotRight - plotLeft);
                    }

                    double yFor(double v) {
                      final double frac =
                          (v - plotValueMin) / (plotValueMax - plotValueMin);
                      return plotBottom +
                          frac.clamp(0.0, 1.0) * (plotTop - plotBottom);
                    }

                    void drawDashed(double y, PdfColor lineColor) {
                      canvas
                        ..setStrokeColor(lineColor)
                        ..setLineWidth(0.75)
                        ..setLineDashPattern([2, 2])
                        ..drawLine(plotLeft, y, plotRight, y)
                        ..strokePath()
                        ..setLineDashPattern([]);
                    }

                    if (safeMin != null)
                      drawDashed(yFor(safeMin), safeLineColor);
                    if (safeMax != null)
                      drawDashed(yFor(safeMax), safeLineColor);
                    if (healthyMin != null)
                      drawDashed(yFor(healthyMin), healthyLineColor);
                    if (healthyMax != null)
                      drawDashed(yFor(healthyMax), healthyLineColor);
                    if (targetValue != null)
                      drawDashed(yFor(targetValue), targetLineColor);

                    canvas.setColor(accent);
                    for (final point in sorted) {
                      canvas
                        ..drawEllipse(
                          xFor(point.key),
                          yFor(point.value),
                          1.8,
                          1.8,
                        )
                        ..fillPath();
                    }
                  },
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(formatDate(start), style: helperStyle),
                  pw.Text(formatDate(end), style: helperStyle),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: borderSubtle, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'Report generated by CWICare © ${DateTime.now().year} - from the patient\'s own records',
                style: helperStyle,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: helperStyle,
            ),
          ],
        ),
      ],
    );
  }

  static Future<Uint8List> buildDocument({
    required String title,
    required List<pw.Widget> Function() build,
  }) async {
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
