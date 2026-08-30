import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_severity_scale.dart';
import '../classes/database_manager.dart';
import '../classes/patient_pain.dart';
import '../classes/sickness_episode.dart';

// Opened whenever "Sick" is tapped on the mood widget (medical_profile_screen.dart) —
// the sentiment itself is already recorded by the caller before this even opens, same
// as MoodCheckInScreen. Two stages: pick what's going on (or dismiss as "just sick,"
// which skips straight to done with no severity ask — see SicknessEpisode's own doc
// comment for why severity is only asked once something more specific is named), then
// rank it with the same DetailedPainLevel scale the real Symptoms feature uses. Once
// saved, the daily "are you still sick?" cadence is SicknessRecheckReminder's job, not
// this screen's.
class SicknessCheckInScreen extends StatefulWidget {
  final String patientUuid;

  const SicknessCheckInScreen({super.key, required this.patientUuid});

  @override
  State<SicknessCheckInScreen> createState() => _SicknessCheckInScreenState();
}

class _SicknessCheckInScreenState extends State<SicknessCheckInScreen> {
  final Set<String> _selectedChips = {};
  bool _rankingSeverity = false;
  DetailedPainLevel _severity = DetailedPainLevel.mild;
  bool _saving = false;

  Future<void> _saveJustSick() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _saveEpisode(symptoms: const [], severity: null);
  }

  void _continueToSeverity() {
    if (_selectedChips.isEmpty) return;
    setState(() => _rankingSeverity = true);
  }

  Future<void> _saveWithSeverity() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _saveEpisode(symptoms: _selectedChips.toList(), severity: _severity.index);
  }

  Future<void> _saveEpisode({required List<String> symptoms, int? severity}) async {
    final existing = await DatabaseManager().getActiveSicknessEpisode(widget.patientUuid);
    if (existing != null) {
      await DatabaseManager().updateSicknessEpisodeIntake(
        id: existing['id'] as String,
        existingSymptoms: SicknessEpisode.fromRow(existing).symptoms,
        newSymptoms: symptoms,
        severity: severity,
      );
    } else {
      await DatabaseManager().insertSicknessEpisode(
        patientUuid: widget.patientUuid,
        symptoms: symptoms,
        severity: severity,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Feeling Sick", style: CarbonTheme.carbonLabelTextStyle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _rankingSeverity ? _buildSeverityStage() : _buildIntakeStage(),
        ),
      ),
    );
  }

  Widget _buildIntakeStage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sorry to hear that.", style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 8),
          Text(
            "Is there anything more specific going on? Pick what applies, or let us know if it's just a general feeling.",
            style: CarbonTheme.carbonHintTextStyle,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in sicknessSymptomChips)
                ChoiceChip(
                  label: Text(chip),
                  selected: _selectedChips.contains(chip),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedChips.add(chip);
                    } else {
                      _selectedChips.remove(chip);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 28),
          CarbonCompactButton(
            icon: Symbols.arrow_forward,
            label: "Continue",
            style: CarbonButtonStyle.primary,
            onTap: _selectedChips.isEmpty ? () {} : _continueToSeverity,
          ),
          const SizedBox(height: 12),
          CarbonCompactButton(
            icon: Symbols.check,
            label: _saving ? "Saving..." : "Just Feeling Sick",
            style: CarbonButtonStyle.ghost,
            onTap: _saving ? () {} : _saveJustSick,
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityStage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("How severe does it feel?", style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 8),
          Text(
            "The same scale you'd use for an ache or pain.",
            style: CarbonTheme.carbonHintTextStyle,
          ),
          const SizedBox(height: 20),
          CarbonSeverityScale<DetailedPainLevel>(
            value: _severity,
            items: DetailedPainLevel.values,
            onChanged: (val) => setState(() => _severity = val),
          ),
          const SizedBox(height: 28),
          CarbonCompactButton(
            icon: Symbols.check,
            label: _saving ? "Saving..." : "Save",
            style: CarbonButtonStyle.primary,
            onTap: _saving ? () {} : _saveWithSeverity,
          ),
        ],
      ),
    );
  }
}
