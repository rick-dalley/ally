import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_checkbox.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';
import '../classes/database_manager.dart';
import '../classes/frequency_codes.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../classes/uuid.dart';

// Common therapy types as one-tap chips (each carries a category tag purely for the
// list/reminder icon later) — anything typed instead just becomes a new chip candidate
// next time via DatabaseManager.getDistinctCareOrderLabels, no separate table needed.
const List<(String label, String category)> _builtInTherapies = [
  ('Physical Therapy', 'physical_therapy'),
  ('Cane', 'cane'),
  ('Walker', 'walker'),
  ('Cast', 'cast'),
  ('Bed Rest', 'bed_rest'),
];

// Self-directed only — a doctor's order arrives via Progressor's discharge handoff
// instead (see ImportCarePlanScreen). Same frequency-code system medications use
// (CarbonDropdown + FrequencyCodes), not a separate cadence concept, since a
// therapy's schedule is the same kind of thing a prescription's is.
class AddTherapyScreen extends StatefulWidget {
  final Patient patient;

  const AddTherapyScreen({super.key, required this.patient});

  @override
  State<AddTherapyScreen> createState() => _AddTherapyScreenState();
}

class _AddTherapyScreenState extends State<AddTherapyScreen> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _directionsController = TextEditingController();
  String? _selectedCategory; // null once the label no longer matches a built-in chip
  FrequencyCodes _frequency = FrequencyCodes.quaqueDie;
  TimeOfDay? _specificTime;
  final Set<ReminderChannel> _channels = {ReminderChannel.chime};
  List<String> _pastLabels = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPastLabels();
  }

  Future<void> _loadPastLabels() async {
    final labels = await DatabaseManager().getDistinctCareOrderLabels(widget.patient.patientUuid);
    final Set<String> builtInLabels = _builtInTherapies.map((t) => t.$1).toSet();
    final List<String> customOnly = labels.where((l) => !builtInLabels.contains(l)).toList();
    if (!mounted) return;
    setState(() => _pastLabels = customOnly);
  }

  void _pickChip(String label, String? category) {
    setState(() {
      _labelController.text = label;
      _selectedCategory = category;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _specificTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _specificTime = picked);
  }

  void _toggleChannel(ReminderChannel channel) {
    setState(() {
      if (_channels.contains(channel)) {
        _channels.remove(channel);
      } else {
        _channels.add(channel);
      }
    });
  }

  Future<void> _save() async {
    final String label = _labelController.text.trim();
    if (label.isEmpty || _saving) return;
    setState(() => _saving = true);

    final String careOrderId = uuid.v4();
    final bool hasSchedule = _frequency != FrequencyCodes.proReNata;
    final String? reminderTime = _specificTime != null
        ? '${_specificTime!.hour.toString().padLeft(2, '0')}:${_specificTime!.minute.toString().padLeft(2, '0')}'
        : null;

    await DatabaseManager().insertCareOrder(
      id: careOrderId,
      patientUuid: widget.patient.patientUuid,
      label: label,
      directions: _directionsController.text.trim().isEmpty ? null : _directionsController.text.trim(),
      frequency: _frequency.latin,
      source: 'Self-directed',
      freqCode: hasSchedule ? _frequency.code : null,
      reminderTime: reminderTime,
      therapyCategory: _selectedCategory,
    );

    await DatabaseManager().saveCareOrderReminderPreference(
      careOrderId: careOrderId,
      patientUuid: widget.patient.patientUuid,
      enabled: hasSchedule && _channels.isNotEmpty,
      channels: _channels,
      leadMinutes: 0,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add a Therapy", style: CarbonTheme.carbonLabelTextStyle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What is it?", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final therapy in _builtInTherapies)
                  ChoiceChip(
                    label: Text(therapy.$1),
                    selected: _labelController.text == therapy.$1,
                    onSelected: (_) => _pickChip(therapy.$1, therapy.$2),
                  ),
                for (final label in _pastLabels)
                  ChoiceChip(
                    label: Text(label),
                    selected: _labelController.text == label,
                    onSelected: (_) => _pickChip(label, null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CarbonTextInput(
              label: "Or type a new one",
              controller: _labelController,
              onChanged: (val) {
                final bool matchesBuiltIn = _builtInTherapies.any((t) => t.$1 == val);
                if (!matchesBuiltIn && _selectedCategory != null) {
                  setState(() => _selectedCategory = null);
                }
              },
            ),
            const SizedBox(height: 16),
            CarbonTextInput(label: "Notes (optional)", controller: _directionsController, maxLines: 2, onChanged: (_) {}),
            const SizedBox(height: 20),
            Text("HOW OFTEN", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 6),
            CarbonDropdown(
              label: "Frequency",
              helperText: "As needed if there's no fixed schedule to remind you about",
              placeholder: "Select the frequency",
              items: FrequencyCodes.values,
              value: _frequency,
              onChanged: (Listable val) => setState(() => _frequency = val as FrequencyCodes),
            ),
            if (_frequency != FrequencyCodes.proReNata) ...[
              const SizedBox(height: 16),
              Text("WHAT TIME (OPTIONAL)", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              CarbonCompactButton(
                icon: Symbols.schedule,
                label: _specificTime != null ? _specificTime!.format(context) : "Use ${_frequency.label} default",
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              Text("HOW TO REMIND YOU", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 6),
              ...ReminderChannel.values.map(
                (channel) => CarbonCheckboxListTile(
                  value: _channels.contains(channel),
                  onChanged: (_) => _toggleChannel(channel),
                  title: Text(channel.label),
                ),
              ),
            ],
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: _saving ? "Saving..." : "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
