import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/interfaces/flyable.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_flyout_widget.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

import '../classes/database_manager.dart';
import '../classes/patient_life_event.dart';
import '../classes/patient_sentiment.dart';

// Capture (or correct) one life event from the diary — the retrospective half of the
// same thing MoodCheckInScreen captures in the moment. The diary navigates by day, so
// this is where "I forgot to write down Tuesday" gets handled; whatever day the diary
// is showing is the day the event is stamped with, not today.
//
// Returns true when something was actually written or deleted, so the caller knows to
// reload the day rather than guessing.
Future<bool> showLifeEventSheet(
  BuildContext context, {
  required String patientUuid,
  required DateTime day,
  PatientLifeEvent? existing,
}) async {
  final bool? changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      // Lifts the sheet clear of the keyboard — the title field takes focus as soon
      // as this opens, so without this the fields sit behind it on a phone.
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _LifeEventSheet(patientUuid: patientUuid, day: day, existing: existing),
    ),
  );
  return changed ?? false;
}

class _LifeEventSheet extends StatefulWidget {
  final String patientUuid;
  final DateTime day;
  final PatientLifeEvent? existing;

  const _LifeEventSheet({required this.patientUuid, required this.day, this.existing});

  @override
  State<_LifeEventSheet> createState() => _LifeEventSheetState();
}

class _LifeEventSheetState extends State<_LifeEventSheet> {
  late final TextEditingController _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _noteController = TextEditingController(text: widget.existing?.note ?? '');
  late Sentiment? _mood = widget.existing?.mood;
  List<String> _suggestions = [];
  bool _saving = false;

  bool get _isEditing => widget.existing?.id != null;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final List<String> titles = await DatabaseManager().getLifeEventTitleSuggestions(widget.patientUuid);
    if (!mounted) return;
    setState(() => _suggestions = titles);
  }

  // Noon for a past day, the actual time for today — a retrospective entry has no real
  // clock time behind it, and stamping midnight would sort it above everything that
  // genuinely happened that morning.
  DateTime get _occurredAt {
    if (widget.existing != null) return widget.existing!.occurredAt;
    final DateTime now = DateTime.now();
    final bool isToday = widget.day.year == now.year && widget.day.month == now.month && widget.day.day == now.day;
    return isToday ? now : DateTime(widget.day.year, widget.day.month, widget.day.day, 12);
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);

    if (_isEditing) {
      await DatabaseManager().updateLifeEvent(
        widget.existing!.id!,
        title: title,
        note: _noteController.text,
        mood: _mood?.index,
      );
    } else {
      await DatabaseManager().insertLifeEvent(
        widget.patientUuid,
        title,
        note: _noteController.text,
        mood: _mood?.index,
        occurredAt: _occurredAt,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    await DatabaseManager().deleteLifeEvent(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? "Edit what happened" : "Something that happened",
              style: CarbonTheme.carbonHeadingTextStyle,
            ),
            const SizedBox(height: 4),
            Text(
              "A recital, a bad phone call, lunch with a friend — anything that mattered, "
              "however small.",
              style: CarbonTheme.carbonHelperTextStyle,
            ),
            const SizedBox(height: 16),
            CarbonTextInput(
              label: "What happened?",
              controller: _titleController,
              maxLines: 1,
              onChanged: (_) => setState(() {}),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final String suggestion in _suggestions)
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () => setState(() => _titleController.text = suggestion),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            CarbonTextInput(
              label: "Anything more about it",
              helperText: "Optional.",
              controller: _noteController,
              maxLines: 4,
              onChanged: (_) {},
            ),
            const SizedBox(height: 20),
            Text(
              _mood == null ? "How did it make you feel?" : "It made you feel ${_mood!.label.toLowerCase()}.",
              style: CarbonTheme.carbonLabelTextStyle,
            ),
            const SizedBox(height: 4),
            Text("Optional — skip it if you'd rather not say.", style: CarbonTheme.carbonHelperTextStyle),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: CarbonFlyOutWidget(
                children: Sentiment.values,
                style: CarbonButtonStyle.tertiary,
                selectedItem: (_mood ?? Sentiment.neutral).index,
                onSelected: (Flyable item) => setState(() => _mood = item as Sentiment),
              ),
            ),
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: _saving ? "Saving..." : "Save",
              style: CarbonButtonStyle.primary,
              onTap: (_saving || _titleController.text.trim().isEmpty) ? null : _save,
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              CarbonCompactButton(
                icon: Symbols.delete,
                label: "Delete",
                style: CarbonButtonStyle.ghost,
                onTap: _saving ? null : _delete,
              ),
            const SizedBox(height: 8),
            CarbonCompactButton(
              icon: Symbols.close,
              label: "Cancel",
              style: CarbonButtonStyle.ghost,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
