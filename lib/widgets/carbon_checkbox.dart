import 'package:flutter/material.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

// A sharp-cornered square rather than Material's default rounded one — matching
// Carbon's flat aesthetic. Filled with carbonColorButtonPrimary (the real IBM Carbon
// interactive blue token) when checked. AppColors.mustard was tried here first and
// corrected — it's not a Carbon color at all, just a separate, non-Carbon palette that
// had crept into a few screens; every color in this app should trace back to
// carbon_color_constants.dart, not that file. No CarbonCheckbox existed anywhere
// before now; every checkbox site (this one included) had silently reached for the
// bare Material widget instead.
class CarbonCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const CarbonCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: const BorderSide(color: carbonColorBorderStrong03, width: 2),
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? carbonColorButtonPrimary : Colors.transparent;
      }),
      checkColor: carbonColorButtonOnPrimary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// The list-tile shape every checkbox call site in this app actually wants (a tappable
// row with a label) — matches CheckboxListTile's API surface so it's a drop-in swap.
class CarbonCheckboxListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget title;
  final EdgeInsetsGeometry contentPadding;
  final bool dense;

  const CarbonCheckboxListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.contentPadding = EdgeInsets.zero,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onChanged(!value),
      leading: CarbonCheckbox(value: value, onChanged: onChanged),
      title: DefaultTextStyle.merge(style: CarbonTheme.carbonTextStyle, child: title),
      contentPadding: contentPadding,
      dense: dense,
    );
  }
}
