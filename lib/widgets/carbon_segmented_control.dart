import 'package:flutter/material.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

// Carbon's flat "content switcher" pattern for a small set of mutually exclusive
// choices — segments sit flush against each other with no gaps, and the selected one
// fills with the primary brand color. This app's first multi-way Carbon selector; the
// boolean case already has CarbonCheckbox.
class CarbonSegmentedControl<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  // Null keeps carbonTextStyle's own size — only set this when a control has enough
  // segments/label length that the default size pushes it onto two lines and grows
  // the whole control taller than intended.
  final double? fontSize;

  const CarbonSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: option == value
                      ? carbonColorButtonPrimary
                      : carbonColorField,
                  border: Border(
                    top: const BorderSide(
                      color: carbonColorBorderStrong03,
                      width: 1,
                    ),
                    bottom: const BorderSide(
                      color: carbonColorBorderStrong03,
                      width: 1,
                    ),
                    left: const BorderSide(
                      color: carbonColorBorderStrong03,
                      width: 1,
                    ),
                    right: option == options.last
                        ? const BorderSide(
                            color: carbonColorBorderStrong03,
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  labelBuilder(option),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CarbonTheme.carbonTextStyle?.copyWith(
                    color: option == value
                        ? carbonColorButtonOnPrimary
                        : carbonColorTextPrimary,
                    fontWeight: option == value
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
