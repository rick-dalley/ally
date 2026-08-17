import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'body_markers.dart';
import 'body_zone.dart';
import 'patient.dart';
import 'pdf_report_builder.dart';

// Sent from the Symptoms (body map) screen's paper-airplane action — a snapshot of
// whatever's currently marked on the body, in one PDF a patient can hand to a
// provider. The diagram is whatever was actually on screen when they tapped send
// (captured by the caller via RepaintBoundary), not redrawn from scratch here, so it
// always matches what the patient was looking at exactly, dot for dot.
class SymptomReport {
  static Future<Uint8List> build({
    required Patient patient,
    required BodyMarkerGroup currentGroup,
    required List<BodyMarker> currentGroupMarkers,
    required List<BodyMarker> otherMarkers,
    Uint8List? diagramImage,
  }) async {
    return ReportPdfBuilder.buildDocument(
      title: 'Symptom Report',
      build: () => [
        ReportPdfBuilder.patientHeader(patient),
        pw.Text(
          'Symptom Report',
          style: ReportPdfBuilder.titleStyle.copyWith(fontSize: 16),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          "A snapshot of ${patient.firstName}'s currently tracked symptoms, marked on their own body map.",
          style: ReportPdfBuilder.helperStyle,
        ),
        if (diagramImage != null) ...[
          ReportPdfBuilder.sectionHeading(_groupLabel(currentGroup)),
          pw.Center(
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: ReportPdfBuilder.borderSubtle),
              ),
              child: pw.Image(pw.MemoryImage(diagramImage)),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        for (final marker in currentGroupMarkers) _markerDetail(marker),
        if (otherMarkers.isNotEmpty) ...[
          ReportPdfBuilder.sectionHeading('Other Reported Symptoms'),
          for (final marker in otherMarkers) _markerDetail(marker),
        ],
        if (currentGroupMarkers.isEmpty && otherMarkers.isEmpty)
          pw.Text(
            'No active symptoms are currently tracked.',
            style: ReportPdfBuilder.helperStyle,
          ),
      ],
    );
  }

  static pw.Widget _markerDetail(BodyMarker marker) {
    final String location = marker.medicalName.isNotEmpty
        ? '${marker.name} (${marker.medicalName})'
        : marker.name;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: ReportPdfBuilder.borderSubtle, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            location[0].toUpperCase() + location.substring(1),
            style: ReportPdfBuilder.bodyStyle.copyWith(
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          if (marker.severity != null)
            ReportPdfBuilder.keyValue('Pain Level', marker.severity!.label),
          if (marker.frequency != null)
            ReportPdfBuilder.keyValue('Frequency', marker.frequency!.label),
          if (marker.nature != null)
            ReportPdfBuilder.keyValue('Type', marker.nature!.label),
          if (marker.carePlan != null)
            ReportPdfBuilder.keyValue('Plan', marker.carePlan!.label),
          if ((marker.descriptions ?? '').isNotEmpty)
            ReportPdfBuilder.keyValue('Description', marker.descriptions!),
          if ((marker.worsensWhen ?? '').isNotEmpty)
            ReportPdfBuilder.keyValue('Worse when', marker.worsensWhen!),
          if ((marker.improvesWhen ?? '').isNotEmpty)
            ReportPdfBuilder.keyValue('Better when', marker.improvesWhen!),
          if ((marker.interventionsTried ?? '').isNotEmpty)
            ReportPdfBuilder.keyValue('Tried', marker.interventionsTried!),
        ],
      ),
    );
  }

  static String _groupLabel(BodyMarkerGroup group) {
    switch (group) {
      case BodyMarkerGroup.bodyFront:
        return 'Body — Front';
      case BodyMarkerGroup.bodyBack:
        return 'Body — Back';
      case BodyMarkerGroup.leftHandFront:
        return 'Left Hand — Front';
      case BodyMarkerGroup.leftHandBack:
        return 'Left Hand — Back';
      case BodyMarkerGroup.rightHandFront:
        return 'Right Hand — Front';
      case BodyMarkerGroup.rightHandBack:
        return 'Right Hand — Back';
      case BodyMarkerGroup.leftFootTop:
        return 'Left Foot — Top';
      case BodyMarkerGroup.leftFootBottom:
        return 'Left Foot — Bottom';
      case BodyMarkerGroup.rightFootTop:
        return 'Right Foot — Top';
      case BodyMarkerGroup.rightFootBottom:
        return 'Right Foot — Bottom';
      case BodyMarkerGroup.face:
        return 'Face';
      case BodyMarkerGroup.none:
        return 'Body Map';
    }
  }
}
