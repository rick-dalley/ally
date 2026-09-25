import 'package:flutter/material.dart';
import 'package:carbon_ui/widgets/carbon_style_separators.dart';
import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/medication_services.dart';

class GetMedicationType extends StatefulWidget {
  final Function(MedicationTypes) onTypeSelected;

  /// Pre-selection from a label scan ("...TABLET" printed on the bottle). Null when
  /// nothing was scanned, or when the scan couldn't tell — the person picks as before.
  final MedicationTypes? initialType;

  const GetMedicationType({super.key, required this.onTypeSelected, this.initialType});

  @override
  State<GetMedicationType> createState() => _GetMedicationTypeState();
}

class _GetMedicationTypeState extends State<GetMedicationType> {
  MedicationTypes? _selectedType;
  final selectedColor = carbonColorBorderInteractive;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  // A label scan can land after this page has already been built — the PageView
  // builds the step adjacent to the current one ahead of time, so initState has
  // usually already run by the time the scan comes back. Adopting the value only
  // when it actually changed means a rebuild for any other reason can never
  // overwrite a type the person picked by hand.
  @override
  void didUpdateWidget(covariant GetMedicationType oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialType != oldWidget.initialType && widget.initialType != null) {
      setState(() => _selectedType = widget.initialType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The hosting sheet already lifts for the keyboard; a nested Scaffold left on
      // the default would subtract that height again and squeeze this step's list to
      // nothing. See AddMedicationWizard's build for the full chain.
      resizeToAvoidBottomInset: false,
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
