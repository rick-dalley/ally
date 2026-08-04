import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_separators.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

class CarbonNumberInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? placeHolderText;
  final String? suffix;
  final dynamic value;
  final TextEditingController controller;
  final int step;
  final Color? fillColor;
  final Color? accentColor;
  final CarbonInputs? inputs;
  final bool? enabled;
  final FocusNode? focusNode;
  final bool? decimals;
  const CarbonNumberInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.placeHolderText,
    this.suffix,
    this.step = 1,
    this.fillColor,
    this.accentColor,
    this.inputs,
    this.enabled,
    this.value,
    this.focusNode,
    this.decimals,
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
    bool isDouble = decimals ?? false;
    if (value != null && controller.text.isEmpty) {
      controller.text = value.toString();
    }
    CarbonInputs chosenInput = inputs ?? CarbonInputs.medium;
    Color fillColor = this.fillColor ?? carbonColorField;
    Color accentColor = this.accentColor ?? carbonColorButtonPrimary;
    bool isEnabled = enabled ?? true;
    String promptText = placeHolderText ?? "0";
    String chosenSuffix = suffix ?? "";
    double separatorHeight = chosenInput.size.height - 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(label, style: CarbonTheme.carbonLabelTextStyle),
        ),
        // Unified Container for Input + Stepper
        Container(
          height: chosenInput.size.height,
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
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fillColor,
                    hintStyle: CarbonTheme.carbonHintTextStyle,
                    hintText: promptText,
                    contentPadding: EdgeInsets.all(chosenInput.edgeInsetSize.width),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 2)),
                    errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorButtonDanger, width: 1)),
                    errorStyle: GoogleFonts.ibmPlexSans(color: carbonColorButtonOnDanger),
                    suffix: Text(chosenSuffix, style: CarbonTheme.carbonTextStyle),
                    suffixIcon: isEnabled & !isDouble
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CarbonVerticalSeparator(height: separatorHeight),
                              SizedBox(width: 4),
                              CarbonIconButton(
                                onPressed: _decrement,
                                icon: Symbols.remove,
                                style: CarbonButtonStyle.stepper,
                              ),
                              CarbonIconButton(
                                onPressed: _increment,
                                icon: Symbols.add,
                                style: CarbonButtonStyle.stepper,
                              ),
                              const SizedBox(width: 4),
                            ],
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Helper Text Section
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(hint!, style: CarbonTheme.carbonHelperTextStyle),
          ),
      ],
    );
  }
}
