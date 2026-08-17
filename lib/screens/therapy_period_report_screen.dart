import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/patient.dart';
import '../classes/therapy_period_report.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import '../widgets/report_preview_screen.dart';

// How far back to go is the patient's call, not the app's — see the design discussion
// this screen came out of. Defaults to 30 days as a reasonable "since my last
// appointment" starting point, freely adjustable.
class TherapyPeriodReportScreen extends StatefulWidget {
  final Patient patient;
  const TherapyPeriodReportScreen({super.key, required this.patient});

  @override
  State<TherapyPeriodReportScreen> createState() => _TherapyPeriodReportScreenState();
}

class _TherapyPeriodReportScreenState extends State<TherapyPeriodReportScreen> {
  late DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();

  Future<void> _pickStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: _end,
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _end = picked);
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  void _generate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          title: "Progress Report",
          buildPdf: () => TherapyPeriodReport.build(patient: widget.patient, start: _start, end: _end),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Progress Report", style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shows medication adherence, readings, mood, symptoms, and your own notes "
              "for whatever stretch of time you pick — useful for \"here's what's happened "
              "since my last appointment.\"",
              style: CarbonTheme.carbonHelperTextStyle,
            ),
            const SizedBox(height: 20),
            CarbonCompactButton(
              icon: Symbols.event,
              label: "From: ${_formatDate(_start)}",
              style: CarbonButtonStyle.secondary,
              onTap: _pickStart,
            ),
            const SizedBox(height: 8),
            CarbonCompactButton(
              icon: Symbols.event,
              label: "To: ${_formatDate(_end)}",
              style: CarbonButtonStyle.secondary,
              onTap: _pickEnd,
            ),
            const Spacer(),
            CarbonCompactButton(
              icon: Symbols.description,
              label: "Generate Report",
              style: CarbonButtonStyle.primary,
              onTap: _generate,
            ),
          ],
        ),
      ),
    );
  }
}
