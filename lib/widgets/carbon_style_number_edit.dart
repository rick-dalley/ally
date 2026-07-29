import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/widgets/carbon_style_separators.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

class CarbonNumberInput extends StatelessWidget {
  final String label;
  final String? helperText;
  final TextEditingController controller;
  final int step;
  final Color? fillColor;
  final Color? accentColor;
  const CarbonNumberInput({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
    this.step = 1,
    this.fillColor,
    this.accentColor,
  });

  void _increment() {
    int current = int.tryParse(controller.text) ?? 0;
    controller.text = (current + step).toString();
  }

  void _decrement() {
    int current = int.tryParse(controller.text) ?? 0;
    if (current > 0) controller.text = (current - step).toString();
  }

  @override
  Widget build(BuildContext context) {
    Color fillColor = this.fillColor ?? carbonColorField;
    // Updated to use carbonColorPrimary as requested for the focused state/accent
    Color accentColor = this.accentColor ?? carbonColorButtonPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(label, style: CarbonTheme.carbonLabelTextStyle),
        ),
        // Unified Container for Input + Stepper
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: carbonColorField,
            border: Border(bottom: BorderSide(color: carbonColorBorderInteractive, width: 0)),
          ),
          child: Row(
            children: [
              // Expanded makes the TextField take up all available horizontal space,
              // pushing the suffix elements cleanly to the far right.
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fillColor,
                    hintStyle: CarbonTheme.carbonHintTextStyle,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 2)),
                    errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorButtonDanger, width: 1)),
                    errorStyle: GoogleFonts.ibmPlexSans(color: carbonColorButtonOnDanger),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CarbonVerticalSeparator(height: 22),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          child: IconButton(
                            icon: const Icon(Symbols.remove, size: 18),
                            onPressed: _decrement,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: IconButton(
                            icon: const Icon(Symbols.add, size: 18),
                            onPressed: _increment,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Helper Text Section
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(helperText!, style: CarbonTheme.carbonHelperTextStyle),
          ),
      ],
    );
  }
}
