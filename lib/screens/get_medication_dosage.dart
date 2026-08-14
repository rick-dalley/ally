import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';
import '../classes/app_colors.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/medication_services.dart';
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
  DosageUnit _unit = DosageUnit.mg;

  void _emitDosage() {
    final String amount = widget.controller.text.trim();
    if (amount.isEmpty) return;
    widget.onAddDosage('$amount ${_unit.label}');
  }

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
              label: "Amount",
              hint: "Enter a number",
              onChanged: (_) => _emitDosage(),
            ),
            const SizedBox(height: 24),
            Text("Unit", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DosageUnit.values.map((unit) {
                final bool isSelected = unit == _unit;
                return GestureDetector(
                  onTap: () {
                    setState(() => _unit = unit);
                    _emitDosage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryColor,
                      border: Border.all(
                        color: isSelected ? AppColors.mustard[3] : AppTheme.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      unit.label,
                      style: TextStyle(
                        color: isSelected ? AppColors.mustard[5] : AppTheme.defaultFontColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(Symbols.medication, size: 64, color: AppTheme.cardBorder),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) {
                      final String amount = value.text.trim();
                      return Text(
                        amount.isEmpty ? "Enter an amount above" : "$amount ${_unit.label} per dose",
                        style: CarbonTheme.carbonHeadingTextStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
