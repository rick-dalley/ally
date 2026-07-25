import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';

class CarbonTextEdit extends StatefulWidget {
  final String label;
  final String? errorText;
  final String? placeHolderText;
  final String? helperText;
  final String? value;
  final Color? fillColor;
  final Color? accentColor;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  const CarbonTextEdit({
    super.key,
    this.controller,
    required this.label,
    this.value,
    this.fillColor,
    this.accentColor,
    this.helperText,
    this.placeHolderText,
    this.errorText,
    this.keyboardType,
  });

  @override
  State<StatefulWidget> createState() => CarbonStateText();
}

class CarbonStateText extends State<CarbonTextEdit> {
  late Color fillColor = widget.fillColor ?? carbonColorField;
  late Color accentColor = widget.accentColor ?? AppTheme.primaryColor;
  late TextEditingController _controller;
  late TextInputType _keyboard;
  @override
  void initState() {
    super.initState();
    // Use the provided controller if it exists, otherwise create one
    _controller = widget.controller ?? TextEditingController();
    _controller.text = widget.value ?? "";
    _keyboard = widget.keyboardType ?? TextInputType.text;
  }

  @override
  void didUpdateWidget(covariant CarbonTextEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text if the value property actually changes
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value ?? "";
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller ourselves
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
          controller: _controller,
          style: CarbonTheme.carbonTextStyle,
          keyboardType: _keyboard,
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
