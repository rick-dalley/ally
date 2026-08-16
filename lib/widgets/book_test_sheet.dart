import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medical_test.dart';
import '../classes/reminder_registry.dart';
import 'carbon_button_compact.dart';
import 'carbon_style_textbox.dart';

// Step two of adding a tracked test, after picking one from TestCatalogPickerSheet —
// when to be reminded, and any special instructions the lab gave (e.g. "no calcium
// supplements for 2 weeks before a bone density scan"). Mirrors BookAppointmentSheet's
// shape since this is the same kind of "schedule something out-of-house" action.
class BookTestSheet extends StatefulWidget {
  final String patientUuid;
  final TestCatalogEntry catalogEntry;

  const BookTestSheet({super.key, required this.patientUuid, required this.catalogEntry});

  @override
  State<BookTestSheet> createState() => _BookTestSheetState();
}

class _BookTestSheetState extends State<BookTestSheet> {
  DateTime? _when;
  final TextEditingController _instructionsController = TextEditingController();
  String? _error;
  bool _saving = false;

  Future<void> _pickWhen() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      _when = date;
      _error = null;
    });
  }

  Future<void> _save() async {
    final DateTime? when = _when;
    if (when == null) {
      setState(() => _error = "Pick a reminder date first.");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final String? instructions = _instructionsController.text.trim().isEmpty
        ? null
        : _instructionsController.text.trim();

    // A save must never fail silently — surface the real exception on screen instead
    // of leaving the sheet just sitting there with no explanation.
    try {
      await DatabaseManager().addPatientTest(widget.patientUuid, {
        'name': widget.catalogEntry.name,
        'category': widget.catalogEntry.category,
        'last_done': null,
        'next_due': when.toIso8601String(),
        'notes': instructions,
      });
    } catch (error, stackTrace) {
      debugPrint('[BookTestSheet] addPatientTest failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Save failed: $error';
        });
      }
      return;
    }

    // Pop *before* refreshing reminders, not after — see BookAppointmentSheet._book
    // for the full explanation. ReminderRegistry.refresh()'s notifyListeners() can
    // trigger HomeScreen's own auto-popup ReminderSheet on this same Navigator, and
    // Navigator.pop() always pops whatever is currently on top of the stack — if that
    // popup beat us to it, we'd pop the wrong route and this sheet would stay stuck.
    if (mounted) Navigator.pop(context, true);

    try {
      await ReminderRegistry.instance.refresh();
    } catch (error, stackTrace) {
      debugPrint('[BookTestSheet] post-pop reminder refresh failed: $error\n$stackTrace');
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.catalogEntry.icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.catalogEntry.name, style: CarbonTheme.carbonHeadingTextStyle),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CarbonCompactButton(
              icon: Symbols.event,
              label: _when == null ? "Pick a Reminder Date" : _formatDate(_when!),
              style: CarbonButtonStyle.secondary,
              onTap: _pickWhen,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: CarbonTheme.dangerTextStyle),
            ],
            const SizedBox(height: 20),
            CarbonTextInput(
              label: "Special Instructions from the Lab (optional)",
              helperText: "e.g. \"No calcium supplements for 2 weeks before this test\"",
              controller: _instructionsController,
              maxLines: 3,
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? () {} : _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
