import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_theme.dart';
import '../classes/medication_services.dart';

class GetMedicationShape extends StatelessWidget {
  final Function(MedicationShapes) onShapeSelect;
  final MedicationShapes? shape;
  const GetMedicationShape({super.key, required this.onShapeSelect, this.shape});

  @override
  Widget build(BuildContext context) {
    MedicationShapes? selectedShape = shape;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isPortrait = constraints.maxWidth < constraints.maxHeight;
          int crossAxisCount = isPortrait ? 3 : 5;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0, // Ensures squares
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final shape = MedicationShapes.values[index];
                    final isSelected = shape == selectedShape;

                    return GestureDetector(
                      onTap: () => onShapeSelect(shape),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.clinicalWhite,
                          border: Border.all(
                            color: isSelected ? AppColors.peacockBlue : AppTheme.carbonFieldBorder,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  "assets/images/pills/${shape.svg}",
                                  colorFilter: ColorFilter.mode(AppColors.foamGreen, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                shape.name.toUpperCase(),
                                style: TextStyle(fontSize: 18, color: AppTheme.carbonLabelFontColor),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: MedicationShapes.values.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
