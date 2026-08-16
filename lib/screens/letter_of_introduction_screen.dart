import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/letter_of_introduction_report.dart';
import '../classes/patient.dart';
import '../widgets/carbon_button_compact.dart';
import '../widgets/carbon_style_textbox.dart';
import '../widgets/report_preview_screen.dart';

class LetterOfIntroductionScreen extends StatefulWidget {
  final Patient patient;
  const LetterOfIntroductionScreen({super.key, required this.patient});

  @override
  State<LetterOfIntroductionScreen> createState() => _LetterOfIntroductionScreenState();
}

class _LetterOfIntroductionScreenState extends State<LetterOfIntroductionScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _generate() {
    final String notes = _notesController.text;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          title: "Letter of Introduction",
          buildPdf: () => LetterOfIntroductionReport.build(patient: widget.patient, additionalNotes: notes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Letter of Introduction", style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This pulls together your current medications, allergies, medical history, "
              "and anything currently bothering you into one summary a new doctor can read "
              "at a glance.",
              style: CarbonTheme.carbonHelperTextStyle,
            ),
            const SizedBox(height: 20),
            CarbonTextInput(
              label: "Anything else you'd like to add? (optional)",
              helperText: "Shows up at the end of the letter, in your own words.",
              controller: _notesController,
              maxLines: 6,
              onChanged: (_) {},
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
