import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';

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
    Color fillColor = this.fillColor ?? AppTheme.carbonFieldBackgroundColor;
    Color accentColor = this.accentColor ?? AppColors.peacockBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(label, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppTheme.carbonFieldBorder)),
        ),
        // Unified Container for Input + Stepper
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.carbonFieldBorder,
            border: Border(bottom: BorderSide(color: AppTheme.carbonFieldBorder, width: 0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fillColor,
                    hintStyle: GoogleFonts.ibmPlexSans(color: const Color(0xFFA8A8A8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.carbonFieldBorder, width: 1)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 1)),
                    errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFDA1E28), width: 1)),
                    errorStyle: GoogleFonts.ibmPlexSans(color: const Color(0xFFDA1E28)),
                  ),
                ),
              ),
              // const VerticalDivider(width: 0.5, color: Color(0xFFC6C6C6)),
              _buildStepperButton(Symbols.remove, _decrement),
              const VerticalDivider(width: 0.5, color: Color(0xFFC6C6C6)),
              _buildStepperButton(Symbols.add, _increment),
            ],
          ),
        ),
        // Helper Text Section
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(helperText!, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppTheme.carbonFieldBorder)),
          ),
      ],
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFFF4F4F4),
          border: Border(bottom: BorderSide(color: AppTheme.carbonFieldBorder, width: 1)),
        ),
        child: SizedBox(width: 40, child: Icon(icon, size: 16)),
      ),
    );
  }
}
