import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/medication_services.dart';

class GetMedicationColor extends StatefulWidget {
  final Function(TabletColors) onColorSelect;
  final TabletColors? color;
  const GetMedicationColor({super.key, required this.onColorSelect, this.color});

  @override
  State<StatefulWidget> createState() => GetMedicationColorState();
}

class GetMedicationColorState extends State<GetMedicationColor> {
  TabletColors? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.onPrimaryColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Color", style: CarbonTheme.carbonHeadingTextStyle),
                const SizedBox(height: 8),
                Text("What color is the medication?", style: CarbonTheme.carbonHintTextStyle),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isPortrait = constraints.maxWidth < constraints.maxHeight;
                int crossAxisCount = isPortrait ? 3 : 5;

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: TabletColors.values.length,
                  itemBuilder: (context, index) {
                    final color = TabletColors.values[index];
                    final isSelected = color == _selectedColor;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                        widget.onColorSelect(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryColor,
                          border: Border.all(
                            color: isSelected ? carbonColorBorderInteractive : AppTheme.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                color.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? carbonColorInteractive : AppTheme.defaultFontColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
