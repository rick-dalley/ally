import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';

// Shared by all three report types — printing's PdfPreview widget already gives the
// patient everything they need to review before it goes anywhere: on-device preview,
// then print/share/save via the OS's own native share sheet. Nothing here is locked to
// email specifically, which matches how the rest of this app hands off to the phone's
// own apps rather than building a parallel delivery mechanism.
class ReportPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() buildPdf;

  const ReportPreviewScreen({super.key, required this.title, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: PdfPreview(
        build: (format) => buildPdf(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
