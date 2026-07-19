import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class CarbonStyleExpander extends StatefulWidget {
  final Function(bool) onTap;
  final bool? isExpanded;
  const CarbonStyleExpander({super.key, required this.onTap, required this.isExpanded});

  @override
  State<StatefulWidget> createState() => CarbonStyleExpanderState();
}

class CarbonStyleExpanderState extends State<CarbonStyleExpander> {
  late bool _isExpanded = true;
  @override
  void initState() {
    _isExpanded = widget.isExpanded ?? true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
        widget.onTap(_isExpanded);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Text(
              "Personal Information",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 20),
            ),
            const Spacer(),
            Icon(_isExpanded ? Symbols.keyboard_arrow_up : Symbols.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
