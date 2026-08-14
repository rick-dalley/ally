import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_theme.dart';
import '../classes/app_colors.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/medication_services.dart';
import '../classes/tablet.dart';

class GetMedicationShape extends StatefulWidget {
  final Function(TabletShapes) onShapeSelect;
  final TabletShapes? shape;
  const GetMedicationShape({super.key, required this.onShapeSelect, this.shape});

  @override
  State<StatefulWidget> createState() => GetMedicationShapeState();
}

class GetMedicationShapeState extends State<GetMedicationShape> {
  TabletShapes? _selectedShape;

  @override
  void initState() {
    super.initState();
    _selectedShape = widget.shape;
  }

  @override
  Widget build(BuildContext context) {
    // Neutral tint for the unselected pill glyphs; the accent color only kicks in once chosen.
    final Color glyphColor = AppTheme.defaultFontColor;
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
                Text("Shape", style: CarbonTheme.carbonHeadingTextStyle),
                const SizedBox(height: 8),
                Text("What shape is the medication?", style: CarbonTheme.carbonHintTextStyle),
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
                    childAspectRatio: 1.0, // Ensures squares
                  ),
                  itemCount: TabletShapes.values.length,
                  itemBuilder: (context, index) {
                    final shape = TabletShapes.values[index];
                    final isSelected = shape == _selectedShape;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedShape = shape);
                        widget.onShapeSelect(shape);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryColor,
                          border: Border.all(
                            color: isSelected ? AppColors.mustard[3] : AppTheme.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  'assets/images/pills/${shape.svg}',
                                  width: 40,
                                  height: 40,
                                  colorMapper: PillColorMapper(isSelected ? AppColors.mustard[3] : glyphColor),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                shape.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? AppColors.mustard[5] : AppTheme.defaultFontColor,
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
