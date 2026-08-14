import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../widgets/carbon_style_number_edit.dart';

class GetMedicationDosage extends StatefulWidget {
  final TextEditingController controller;
  final String? dosage;
  final Function(String) onAddDosage;
  const GetMedicationDosage({super.key, this.dosage, required this.controller, required this.onAddDosage});

  @override
  State<StatefulWidget> createState() => GetMedicationDosageState();
}

class GetMedicationDosageState extends State<GetMedicationDosage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.onPrimaryColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dosage", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 8),
            Text("How much do you take at once?", style: CarbonTheme.carbonHintTextStyle),
            const SizedBox(height: 24),
            CarbonNumberInput(
              controller: widget.controller,
              label: "Dosage",
              hint: "Enter the amount of medication (usually mg)",
              onChanged: widget.onAddDosage,
            ),
          ],
        ),
      ),
    );
  }
}
