import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/listable.dart';

class CarbonDropdown<T extends Listable> extends StatelessWidget {
  final String label;
  final Listable value;
  final List<Listable> items;
  final ValueChanged<Listable> onChanged;
  final String? placeholder;
  final String? helperText;
  final String? errorText;

  const CarbonDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.value,
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
          child: Text(label, style: AppTheme.carbonTinyTextStyle),
        ),
        DropdownButtonFormField<Listable>(
          initialValue: value,
          items: [
            for (Listable val in items)
              DropdownMenuItem(
                value: val,
                child: Text(val.label, style: AppTheme.carbonTextStyle),
              ),
          ],
          icon: const Icon(Icons.expand_more, color: Color(0xFF525252)),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTheme.carbonTinyTextStyle,
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF525252), width: 1)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0F62FE), width: 2)),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFDA1E28), width: 2)),
            errorText: errorText,
          ),
          dropdownColor: const Color(0xFFF4F4F4),
          onChanged: (Listable? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
        if (helperText != null && errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(helperText!, style: AppTheme.carbonTextStyle),
          ),
      ],
    );
  }
}

class CarbonButton2LineDropDown<T extends Listable> extends StatelessWidget {
  final String label;
  final Listable value;
  final List<Listable> items;
  final ValueChanged<Listable> onChanged;
  final String? placeholder;
  final String? helperText;
  final String? errorText;

  const CarbonButton2LineDropDown({
    super.key,
    required this.label,
    required this.onChanged,
    required this.value,
    required this.items,
    this.placeholder,
    this.helperText,
    this.errorText,
  });
  @override
  Widget build(BuildContext context) {
    return DropdownButton<Listable>(
      isExpanded: true,
      value: value,
      // Increase itemHeight to accommodate two lines of text
      itemHeight: 70,
      items: [
        for (Listable val in items)
          DropdownMenuItem(
            value: val,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val.label, style: AppTheme.carbonTextStyle),
                Text(
                  val.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
      ],
      onChanged: (Listable? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
}
