import 'package:flutter/material.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/listable.dart';

class CarbonAutocomplete extends StatelessWidget {
  final String label;
  final List<Listable> options;
  final String? placeholder;
  final String? helperText;
  final Function(String)? onChanged;

  const CarbonAutocomplete({
    super.key,
    required this.label,
    required this.options,
    this.placeholder,
    this.helperText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(label, style: CarbonTheme.carbonLabelTextStyle),
        ),
        Autocomplete<Listable>(
          displayStringForOption: (Listable option) => option.label,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Listable>.empty();
            }
            String searchTerm = textEditingValue.text.toLowerCase();

            return options.where((option) => option.label.toLowerCase().contains(searchTerm));
          },
          onSelected: (Listable selection) {
            if (onChanged != null) onChanged!(selection.label);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Listen to every keystroke to support free-form entry
            controller.addListener(() {
              if (onChanged != null) onChanged!(controller.text);
            });

            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: CarbonTheme.carbonLabelTextStyle,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: CarbonTheme.carbonHelperTextStyle,
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF525252), width: 1)),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: carbonColorButtonPrimary, width: 2),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: carbonColorLayer03,
                          child: Text(option.label, style: CarbonTheme.carbonLabelTextStyle),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(helperText!, style: CarbonTheme.carbonHelperTextStyle),
          ),
      ],
    );
  }
}
