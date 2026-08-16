import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';

// A text field for capturing something the app didn't already have a chip for and
// committing it immediately — check to save, X to discard — rather than typing into a
// notes box nobody reads back. The suffix actions only appear once there's something
// to act on.
class CarbonQuickEntryField extends StatefulWidget {
  final String label;
  final String? hintText;
  final Future<void> Function(String value) onSave;

  const CarbonQuickEntryField({super.key, required this.label, this.hintText, required this.onSave});

  @override
  State<CarbonQuickEntryField> createState() => _CarbonQuickEntryFieldState();
}

class _CarbonQuickEntryFieldState extends State<CarbonQuickEntryField> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(text);
    _controller.clear();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: CarbonTheme.carbonLabelTextStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          style: CarbonTheme.carbonFieldTextStyle,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            filled: true,
            fillColor: carbonColorField,
            hintText: widget.hintText,
            hintStyle: CarbonTheme.carbonHintTextStyle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: carbonColorBorderInteractive, width: 1)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: carbonColorButtonPrimary, width: 2)),
            suffixIcon: _controller.text.isEmpty
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.close, size: 18, color: carbonColorIconSecondary),
                        onPressed: _saving ? null : () => setState(() => _controller.clear()),
                      ),
                      _saving
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Symbols.check, size: 20, color: carbonColorSupportSuccess),
                              onPressed: _save,
                            ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
