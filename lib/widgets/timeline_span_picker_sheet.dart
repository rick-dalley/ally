import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/timeline_span.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_checkbox.dart';

// Manual mix-and-match, capped at three — the point of this screen is letting the
// patient notice their own juxtapositions ("wait, my mood dipped right when I paused
// that medication"), not the app deciding for them what's worth comparing.
class TimelineSpanPickerSheet extends StatefulWidget {
  final List<TimelineSpan> available;
  final List<TimelineSpan> initiallySelected;

  const TimelineSpanPickerSheet({super.key, required this.available, required this.initiallySelected});

  @override
  State<TimelineSpanPickerSheet> createState() => _TimelineSpanPickerSheetState();
}

class _TimelineSpanPickerSheetState extends State<TimelineSpanPickerSheet> {
  late List<TimelineSpan> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.initiallySelected);
  }

  void _toggle(TimelineSpan span, bool value) {
    setState(() {
      if (value) {
        if (_selected.length < 3) _selected.add(span);
      } else {
        _selected.removeWhere((s) => s.sourceId == span.sourceId);
      }
    });
  }

  bool _isSelected(TimelineSpan span) => _selected.any((s) => s.sourceId == span.sourceId);

  @override
  Widget build(BuildContext context) {
    final Map<TimelineSpanCategory, List<TimelineSpan>> grouped = {};
    for (final span in widget.available) {
      grouped.putIfAbsent(span.category, () => []).add(span);
    }
    final bool atLimit = _selected.length >= 3;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Compare Up To 3", style: CarbonTheme.carbonHeadingTextStyle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  atLimit ? "You've picked 3 — remove one to swap it out." : "Pick anything you want to see alongside your timeline.",
                  style: CarbonTheme.carbonHelperTextStyle,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: grouped.entries.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Row(
                          children: [
                            Icon(group.key.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(group.key.label, style: CarbonTheme.carbonLabelTextStyle),
                          ],
                        ),
                      ),
                      for (final span in group.value)
                        CarbonCheckboxListTile(
                          value: _isSelected(span),
                          onChanged: (atLimit && !_isSelected(span)) ? (_) {} : (val) => _toggle(span, val ?? false),
                          title: Text(span.label),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CarbonCompactButton(
                icon: Symbols.check,
                label: "Compare",
                style: CarbonButtonStyle.primary,
                onTap: () => Navigator.pop(context, _selected),
              ),
            ),
          ],
        );
      },
    );
  }
}
