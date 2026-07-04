import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarbonDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? placeholder;
  final String? helperText;
  final String? errorText;

  const CarbonDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.placeholder,
    this.helperText,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(label, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: const Color(0xFF525252))),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more, color: Color(0xFF525252)),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.ibmPlexSans(color: const Color(0xFFA8A8A8)),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF525252), width: 1)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0F62FE), width: 2)),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFDA1E28), width: 2)),
            errorText: errorText,
          ),
          dropdownColor: const Color(0xFFF4F4F4),
        ),
        if (helperText != null && errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(helperText!, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: const Color(0xFF525252))),
          ),
      ],
    );
  }
}
