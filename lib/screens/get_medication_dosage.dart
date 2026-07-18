import 'package:flutter/material.dart';
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
      backgroundColor: AppColors.grey.all[0],
      body: Column(
        children: [
          Text("Dosage Amount", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20)),
          CarbonNumberInput(
            controller: widget.controller,
            label: "Dosage",
            helperText: "Enter the amount medication (usually mg)",
          ),
        ],
      ),
    );
  }
}
