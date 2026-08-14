import 'dart:async';

import 'package:flutter/material.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

class CarbonTextInput extends StatefulWidget {
  final String label;
  final String? errorText;
  final String? placeHolderText;
  final String? helperText;
  final String? value;
  final Color? fillColor;
  final Color? accentColor;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final int maxLines;

  const CarbonTextInput({
    super.key,
    required this.label,
    this.controller,
    this.value,
    this.fillColor,
    this.accentColor,
    this.helperText,
    this.placeHolderText,
    this.errorText,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<StatefulWidget> createState() => CarbonStateText();
}

class CarbonStateText extends State<CarbonTextInput> {
  late Color fillColor = widget.fillColor ?? carbonColorField;
  late Color accentColor = widget.accentColor ?? carbonColorButtonPrimary;
  late TextInputType keyboard;
  late TextEditingController controller;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    // Use the provided controller if it exists, otherwise create one
    keyboard = widget.keyboardType ?? TextInputType.text;
    controller = widget.controller ?? TextEditingController();
    controller.addListener(onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CarbonTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text if the value property actually changes
    if (widget.value != oldWidget.value) {
      controller.text = widget.value ?? "";
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller ourselves
    if (widget.controller == null) {
      controller.dispose();
    }
    debounceTimer?.cancel();
    super.dispose();
  }

  void onTextChanged() {
    // Cancel the previous timer if the user is still typing
    if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

    // Wait 500ms after the last keystroke before saving
    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (widget.onChanged != null) {
        widget.onChanged!(controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(widget.label, style: CarbonTheme.carbonLabelTextStyle),
        ),
        TextField(
          controller: controller,
          style: CarbonTheme.carbonTextStyle,
          keyboardType: keyboard,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: widget.placeHolderText,
            hintStyle: CarbonTheme.carbonHintTextStyle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 2)),
            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorButtonDanger, width: 2)),
            errorText: widget.errorText,
            errorStyle: CarbonTheme.dangerTextStyle,
          ),
        ),
        // Helper Text
        if (widget.helperText != null && widget.errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16),
            child: Text(widget.helperText!, style: CarbonTheme.carbonHelperTextStyle),
          ),
        SizedBox(height: 4),
      ],
    );
  }
}
