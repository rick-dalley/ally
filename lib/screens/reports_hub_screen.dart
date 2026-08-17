import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/patient.dart';
import 'package:carbon_ui/widgets/carbon_style_action_tile.dart';
import 'letter_of_introduction_screen.dart';
import 'release_of_information_screen.dart';
import 'therapy_period_report_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  final Patient patient;
  const ReportsHubScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports", style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          CarbonActionTile(
            title: "Letter of Introduction",
            subtitle: "A summary for a new doctor — history, medications, allergies, current concerns",
            icon: Symbols.article,
            iconColor: carbonColorIconInterActive,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LetterOfIntroductionScreen(patient: patient)),
            ),
          ),
          CarbonActionTile(
            title: "Progress Report",
            subtitle: "Adherence, readings, and observations since a date you choose",
            icon: Symbols.summarize,
            iconColor: carbonColorIconInterActive,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TherapyPeriodReportScreen(patient: patient)),
            ),
          ),
          CarbonActionTile(
            title: "Request Records",
            subtitle: "Ask a provider's office to release your records",
            icon: Symbols.contact_mail,
            iconColor: carbonColorIconInterActive,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReleaseOfInformationScreen(patient: patient)),
            ),
          ),
        ],
      ),
    );
  }
}
