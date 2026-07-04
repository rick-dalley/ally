import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';

class CarbonTextEdit extends StatefulWidget {
  final String label;
  final String? errorText;
  final String? placeHolderText;
  final String? helperText;
  final Color? fillColor;
  final Color? accentColor;
  final TextEditingController? controller;

  const CarbonTextEdit({
    super.key,
    this.controller,
    required this.label,
    this.fillColor,
    this.accentColor,
    this.helperText,
    this.placeHolderText,
    this.errorText,
  });

  @override
  State<StatefulWidget> createState() => CarbonStateText();
}

class CarbonStateText extends State<CarbonTextEdit> {
  late Color fillColor = widget.fillColor ?? Color(0xFFF4F4F4);
  late Color accentColor = widget.accentColor ?? AppTheme.deepLogicViolet;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            widget.label,
            style: GoogleFonts.ibmPlexSans(fontSize: 12, color: const Color(0xFF525252), fontWeight: FontWeight.w400),
          ),
        ),
        TextField(
          controller: widget.controller,
          style: GoogleFonts.ibmPlexSans(fontSize: 16, color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: widget.placeHolderText,
            hintStyle: GoogleFonts.ibmPlexSans(color: const Color(0xFFA8A8A8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF525252), width: 1)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 2)),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFDA1E28), width: 2)),
            errorText: widget.errorText,
            errorStyle: GoogleFonts.ibmPlexSans(color: const Color(0xFFDA1E28)),
          ),
        ),
        // Helper Text
        if (widget.helperText != null && widget.errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16),
            child: Text(
              widget.helperText!,
              style: GoogleFonts.ibmPlexSans(fontSize: 12, color: const Color(0xFF525252)),
            ),
          ),
        SizedBox(height: 4),
      ],
    );
  }
}
