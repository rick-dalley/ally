import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

class CarbonSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onSearch;
  final String? errorText;
  final String? label;
  final String? hintText;
  final String? promptText;

  const CarbonSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSearch,
    this.errorText,
    this.label,
    this.hintText,
    this.promptText,
  });

  @override
  State<CarbonSearchField> createState() => CarbonSearchFieldState();
}

class CarbonSearchFieldState extends State<CarbonSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateUI);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    // Rebuilds when the text changes to show/hide the clear icon
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.label != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 0.0),
              child: Text(widget.label!, style: CarbonTheme.carbonLabelTextStyle),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: (value) {
                    if (widget.onChanged != null) widget.onChanged!(value);
                  },

                  decoration: InputDecoration(
                    fillColor: carbonColorField,
                    filled: true,
                    hintText: widget.hintText ?? "Enter a value to search",
                    hintStyle: CarbonTheme.carbonHintTextStyle,
                    border: UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: carbonColorButtonPrimary, width: 2),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: carbonColorBorderStrong01, width: 2),
                    ),
                    errorText: widget.errorText,
                    errorStyle: GoogleFonts.ibmPlexSans(color: carbonColorButtonDanger),

                    // Prefix: intentional search trapping
                    prefixIcon: IconButton(
                      icon: Icon(
                        Symbols.search,
                        color: widget.controller.text.isNotEmpty
                            ? carbonColorButtonPrimary
                            : carbonColorButtonSecondary,
                      ),
                      onPressed: () {
                        if (widget.onSearch != null) {
                          widget.onSearch!(widget.controller.text);
                        }
                      },
                    ),

                    // Suffix: Text-clearing utility
                    suffixIcon: widget.controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Symbols.clear, size: 16),
                            onPressed: () {
                              widget.controller.clear();
                              if (widget.onChanged != null) widget.onChanged!("");
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.promptText != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 0.0),
              child: Text(widget.promptText!, style: CarbonTheme.carbonLabelTextStyle),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
