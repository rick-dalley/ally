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
    Color accentColor = this.accentColor ?? AppColors.oceanBlue;

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
                    hintStyle: GoogleFonts.ibmPlexSans(color: AppTheme.carbonPlaceHolderFontColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.carbonFieldBorder, width: 1)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 1)),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.carbonButtonDangerFontColor, width: 1),
                    ),
                    errorStyle: GoogleFonts.ibmPlexSans(color: AppTheme.carbonButtonBorderDangerColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min, // Vital: Keeps the row from expanding to fill the field
                      children: [
                        IconButton(
                          icon: const Icon(Symbols.remove),
                          onPressed: _decrement,
                          constraints: const BoxConstraints(), // Removes default padding to fit better
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Symbols.add),
                          onPressed: _increment,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // const VerticalDivider(width: 0.5, color: Color(0xFFC6C6C6)),
              // _buildStepperButton(icon: Symbols.remove, onTap: _decrement, accentColor: accentColor),
              // VerticalDivider(width: 0.5, color: AppColors.grey.all[3]),
              // _buildStepperButton(icon: Symbols.add, onTap: _increment, accentColor: accentColor),
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

  // Widget _buildStepperButton({
  //   required IconData icon,
  //   required VoidCallback onTap,
  //   required Color accentColor,
  //   bool hasFocus = false,
  // }) {
  //   return InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       height: 40,
  //       decoration: BoxDecoration(
  //         color: Color(0xFFF4F4F4),
  //         border: Border(bottom: BorderSide(color: hasFocus ? accentColor : AppTheme.carbonFieldBorder, width: 1)),
  //       ),
  //       child: SizedBox(width: 40, child: Icon(icon, size: 16)),
  //     ),
  //   );
  // }
}
