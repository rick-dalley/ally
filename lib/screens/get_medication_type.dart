import 'package:flutter/material.dart';
import 'package:triage/widgets/carbon_style_separators.dart';
import '../app_theme.dart';
import '../classes/app_colors.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/medication_services.dart';

class GetMedicationType extends StatefulWidget {
  final Function(MedicationTypes) onTypeSelected;

  const GetMedicationType({super.key, required this.onTypeSelected});

  @override
  State<GetMedicationType> createState() => _GetMedicationTypeState();
}

class _GetMedicationTypeState extends State<GetMedicationType> {
  MedicationTypes? _selectedType;
  final selectedColor = AppColors.mustard[3];
  // Helper to format enum values into display strings
  String _formatType(MedicationTypes type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Type", style: CarbonTheme.carbonHeadingTextStyle),
                const SizedBox(height: 8),
                Text("How is this medication taken?", style: CarbonTheme.carbonHintTextStyle),
              ],
            ),
          ),
          Expanded(
            child: RadioGroup<MedicationTypes>(
              groupValue: _selectedType,
              onChanged: (MedicationTypes? value) {
                setState(() => _selectedType = value);
                if (value != null) widget.onTypeSelected(value);
              },
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: CarbonSpacing.wide.width),
                itemCount: MedicationTypes.values.length,
                // Now this will trigger between each tile
                separatorBuilder: (_, _) => carbonSeparator,
                itemBuilder: (context, index) {
                  final type = MedicationTypes.values[index];
                  return RadioListTile<MedicationTypes>(
                    activeColor: selectedColor,

                    value: type,
                    title: Text(
                      _formatType(type),
                      style: TextStyle(
                        color: (_selectedType == type) ? selectedColor : AppTheme.defaultFontColor,
                        fontWeight: (_selectedType == type) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget get carbonSeparator => CarbonHorizontalSeparator();
}
