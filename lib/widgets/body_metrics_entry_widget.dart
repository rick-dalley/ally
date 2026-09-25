import 'package:flutter/material.dart';

class BodyMetricsEntryWidget extends StatefulWidget {
  final double? weight;
  final double? height;
  final String heightUom;
  final String weightUom;
  final Function(double? weight, double? height) onMetricsChanged;

  const BodyMetricsEntryWidget({
    super.key,
    this.weight,
    this.height,
    this.heightUom = "cm",
    this.weightUom = "kg",
    required this.onMetricsChanged,
  });

  @override
  State<BodyMetricsEntryWidget> createState() => _BodyMetricsEntryWidgetState();
}

class _BodyMetricsEntryWidgetState extends State<BodyMetricsEntryWidget> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    // Controllers are instantiated EXACTLY ONCE here, preserving typed text safely
    _heightController = TextEditingController(text: widget.height?.toString() ?? '');
    _weightController = TextEditingController(text: widget.weight?.toString() ?? '');
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Grabs the live strings straight out of the controllers and emits them simultaneously.
  ///
  /// Called on every edit and again whenever a field loses focus, rather than from an
  /// explicit SAVE button. Both fields are always emitted together, so editing one can
  /// never publish a stale value for the other — which is the only thing the button was
  /// actually buying, and it charged an extra tap for it on a step most people skip.
  void _submitData() {
    final double? parsedHeight = double.tryParse(_heightController.text);
    final double? parsedWeight = double.tryParse(_weightController.text);

    widget.onMetricsChanged(parsedWeight, parsedHeight);
  }

  /// Emitting on edit is what makes "tap Next straight after typing" work: tapping a
  /// button elsewhere on the page does not necessarily pull focus out of a text field,
  /// so focus loss alone would drop the last thing typed.
  Widget _entryField({
    required TextEditingController controller,
    required String label,
    required String uom,
    bool autofocus = false,
  }) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _submitData();
              },
              child: TextFormField(
                controller: controller,
                autofocus: autofocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: label,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => _submitData(),
                onFieldSubmitted: (_) => _submitData(),
              ),
            ),
          ),
          Text(" ($uom)"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _entryField(
                controller: _heightController,
                label: 'Height',
                uom: widget.heightUom,
                autofocus: true,
              ),
              const SizedBox(width: 24),
              _entryField(
                controller: _weightController,
                label: 'Weight',
                uom: widget.weightUom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
