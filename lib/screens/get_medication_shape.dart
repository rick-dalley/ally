import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/medication_services.dart';
import '../classes/tablet.dart';

class GetMedicationShape extends StatefulWidget {
  final Function(TabletShapes) onShapeSelect;
  final TabletShapes? shape;
  // The color picked one step earlier — every glyph renders in this color now
  // (not just the selected one), since these are meant to look like the actual
  // pill the person is holding. Nullable only so the widget can't crash if it's
  // ever reached before a color exists; the wizard always asks color first.
  final TabletColors? color;
  const GetMedicationShape({super.key, required this.onShapeSelect, this.shape, this.color});

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
    // The pill's own color, picked on the previous step — every glyph renders in
    // it, selected or not, so they read as "this is your pill" rather than a
    // generic accent color. Falls back to a neutral if somehow reached with none.
    final Color glyphColor = widget.color?.color ?? AppTheme.defaultFontColor;
    return Scaffold(
      // The hosting sheet already lifts for the keyboard; a nested Scaffold left on
      // the default would subtract that height again and squeeze this step's list to
      // nothing. See AddMedicationWizard's build for the full chain.
      resizeToAvoidBottomInset: false,
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
                            color: isSelected ? carbonColorBorderInteractive : AppTheme.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  // A neutral backdrop behind the glyph itself, not just
                                  // the card — without it, a white pill on this screen's
                                  // white background/card would be invisible. Reads fine
                                  // under every pill color, not just white.
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset(
                                    'assets/images/pills/${shape.svg}',
                                    width: 40,
                                    height: 40,
                                    colorMapper: PillColorMapper(glyphColor),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                shape.label.toUpperCase(),
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
