import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import '../classes/database_manager.dart';
import '../classes/patient_pain.dart';
import '../classes/sickness_episode.dart';
import '../widgets/seek_care_sheet.dart';

// The daily "are you still feeling sick?" check-in — opened from a tap on a
// SicknessRecheckReminder tile (see ReminderTile's special-case) rather than the
// generic action sheet every other Remindable uses, since this is a multi-step
// conversation: still sick? -> how bad is it? -> (sometimes) do you need care?
class SicknessRecheckScreen extends StatefulWidget {
  final String patientUuid;
  final SicknessEpisode episode;

  const SicknessRecheckScreen({super.key, required this.patientUuid, required this.episode});

  @override
  State<SicknessRecheckScreen> createState() => _SicknessRecheckScreenState();
}

enum _Stage { askStillSick, askSeverity, askSeekCare, done }

class _SicknessRecheckScreenState extends State<SicknessRecheckScreen> {
  _Stage _stage = _Stage.askStillSick;
  DetailedPainLevel _severity = DetailedPainLevel.mild;
  bool _dontRemindAgain = false;
  bool _busy = false;

  Future<void> _notSickAnymore() async {
    if (_busy) return;
    setState(() => _busy = true);
    await DatabaseManager().resolveSicknessEpisode(widget.episode.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _stillSick() {
    setState(() {
      _severity = widget.episode.severity ?? DetailedPainLevel.mild;
      _stage = _Stage.askSeverity;
    });
  }

  Future<void> _saveSeverity() async {
    if (_busy) return;
    setState(() => _busy = true);
    final DetailedPainLevel? previous = widget.episode.severity;
    await DatabaseManager().updateSicknessEpisodeCheck(id: widget.episode.id, severity: _severity.index);

    final bool shouldEscalate = !widget.episode.seekCareDismissed &&
        SicknessEpisode.escalates(startedAt: widget.episode.startedAt, previousSeverity: previous, newSeverity: _severity);

    if (!mounted) return;
    if (shouldEscalate) {
      setState(() {
        _busy = false;
        _stage = _Stage.askSeekCare;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _answerSeekCare(bool needsCare) async {
    if (_dontRemindAgain) {
      await DatabaseManager().dismissSicknessSeekCareReminder(widget.episode.id);
    }
    if (!mounted) return;
    if (needsCare) {
      final String symptomLabel = widget.episode.symptoms.isEmpty ? "feeling sick" : widget.episode.symptoms.join(', ').toLowerCase();
      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        builder: (context) => SeekCareSheet(
          patientUuid: widget.patientUuid,
          bodyPart: symptomLabel,
          mode: SeekCareSheetMode.urgent,
          severity: _severity,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checking In", style: CarbonTheme.carbonLabelTextStyle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_stage) {
            _Stage.askStillSick => _buildStillSickStage(),
            _Stage.askSeverity => _buildSeverityStage(),
            _Stage.askSeekCare => _buildSeekCareStage(),
            _Stage.done => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildStillSickStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Are you still feeling sick?", style: CarbonTheme.carbonHeadingTextStyle),
        if (widget.episode.symptoms.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text("Last time: ${widget.episode.symptoms.join(', ')}", style: CarbonTheme.carbonHintTextStyle),
        ],
        const SizedBox(height: 28),
        CarbonCompactButton(
          icon: Symbols.check,
          label: _busy ? "Saving..." : "Yes, still not feeling well",
          style: CarbonButtonStyle.primary,
          onTap: _busy ? () {} : _stillSick,
        ),
        const SizedBox(height: 12),
        CarbonCompactButton(
          icon: Symbols.sentiment_satisfied,
          label: "No, I'm feeling better",
          style: CarbonButtonStyle.ghost,
          onTap: _busy ? () {} : _notSickAnymore,
        ),
      ],
    );
  }

  Widget _buildSeverityStage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("How bad is it?", style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 20),
          CarbonButton2LineDropDown<DetailedPainLevel>(
            label: "Severity",
            placeholder: "Select the severity",
            helperText: "Choose the level that best matches how you feel today",
            onChanged: (Listable val) => setState(() => _severity = val as DetailedPainLevel),
            value: _severity,
            items: DetailedPainLevel.values,
          ),
          const SizedBox(height: 28),
          CarbonCompactButton(
            icon: Symbols.check,
            label: _busy ? "Saving..." : "Save",
            style: CarbonButtonStyle.primary,
            onTap: _busy ? () {} : _saveSeverity,
          ),
        ],
      ),
    );
  }

  Widget _buildSeekCareStage() {
    final int daysSick = DateTime.now().difference(widget.episode.startedAt).inDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Do you think you need to seek treatment?", style: CarbonTheme.carbonHeadingTextStyle),
        const SizedBox(height: 8),
        Text(
          daysSick >= 3
              ? "This has been going on for $daysSick days now."
              : "It sounds like this has gotten worse since last time.",
          style: CarbonTheme.carbonHintTextStyle,
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _dontRemindAgain,
          onChanged: (val) => setState(() => _dontRemindAgain = val ?? false),
          title: const Text("Don't ask me this again for this episode"),
        ),
        const SizedBox(height: 20),
        CarbonCompactButton(
          icon: Symbols.medical_services,
          label: "Yes, help me find care",
          style: CarbonButtonStyle.primary,
          onTap: () => _answerSeekCare(true),
        ),
        const SizedBox(height: 12),
        CarbonCompactButton(
          icon: Symbols.close,
          label: "No, not yet",
          style: CarbonButtonStyle.ghost,
          onTap: () => _answerSeekCare(false),
        ),
      ],
    );
  }
}
