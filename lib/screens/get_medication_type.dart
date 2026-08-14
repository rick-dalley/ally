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
                  final bool isSelected = _selectedType == type;
                  return RadioListTile<MedicationTypes>(
                    activeColor: selectedColor,
                    value: type,
                    secondary: Icon(type.icon, color: isSelected ? selectedColor : AppTheme.defaultHintColor),
                    title: Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? selectedColor : AppTheme.defaultFontColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(type.description, style: CarbonTheme.carbonHelperTextStyle),
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
