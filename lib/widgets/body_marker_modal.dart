import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:ally/classes/patient_pain.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_severity_scale.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

import '../classes/body_markers.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import '../classes/symptom_care_plan.dart';
import '../classes/symptom_dismissal_reason.dart';

class BodyMarkerModal extends StatefulWidget {
  final BodyMarker initialMarker;
  final Function(BodyMarker) onSave;
  // Only called when the chosen plan needs a hand-off (call for advice, schedule,
  // seek immediate help, or 911) — not for the two passive-intent plans, which are
  // just recorded on the marker with nothing further to do right now.
  final Function(BodyMarker, SymptomCarePlan) onSeekCare;
  // Called when the X button's reason is confirmed — not for every close (Save and
  // the immediate-action plans close the modal themselves without this).
  final Function(BodyMarker, SymptomDismissalReason) onDismiss;

  const BodyMarkerModal({
    super.key,
    required this.initialMarker,
    required this.onSave,
    required this.onSeekCare,
    required this.onDismiss,
  });

  @override
  State<BodyMarkerModal> createState() => _BodyMarkerModalState();
}

class _BodyMarkerModalState extends State<BodyMarkerModal> {
  late BodyMarker _currentMarker;
  bool _confirmingDismiss = false;
  SymptomDismissalReason _dismissalReason = SymptomDismissalReason.healed;

  // Read only at Save (not on every keystroke via setState) so typing doesn't fight
  // the dropdowns' own rebuilds — _updateMarker pulls the live .text from each of
  // these every time it runs, so whatever's typed is always what gets saved.
  late final TextEditingController _descriptionsController;
  late final TextEditingController _worsensController;
  late final TextEditingController _improvesController;
  late final TextEditingController _interventionsController;

  @override
  void initState() {
    super.initState();
    _currentMarker = widget.initialMarker;
    _descriptionsController = TextEditingController(
      text: _currentMarker.descriptions ?? '',
    );
    _worsensController = TextEditingController(
      text: _currentMarker.worsensWhen ?? '',
    );
    _improvesController = TextEditingController(
      text: _currentMarker.improvesWhen ?? '',
    );
    _interventionsController = TextEditingController(
      text: _currentMarker.interventionsTried ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionsController.dispose();
    _worsensController.dispose();
    _improvesController.dispose();
    _interventionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        // The four new free-text fields push this well past a phone's height on
        // most devices — a fixed-height Container with no scroll wrapper just
        // overflowed off the bottom of the screen instead of clipping or scrolling.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(16),
        width: 400,
        child: SingleChildScrollView(
          child: _confirmingDismiss ? _buildDismissConfirmation() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _currentMarker.name.toUpperCase(),
                style: CarbonTheme.carbonHeadingTextStyle,
              ),
            ),
            CarbonIconButton(
              icon: Symbols.close,
              onPressed: () => setState(() => _confirmingDismiss = true),
            ),
          ],
        ),
        const SizedBox(height: 16),

        CarbonSeverityScale<DetailedPainLevel>(
          label: "Pain Level",
          value: _currentMarker.severity ?? DetailedPainLevel.none,
          items: DetailedPainLevel.values,
          onChanged: (val) => setState(() => _currentMarker = _updateMarker(severity: val)),
        ),
        const SizedBox(height: 16),
        CarbonDropdown<Frequency>(
          label: "Frequency",
          helperText: "Select how often this pain occurs",
          placeholder: "Select the frequency",
          items: Frequency.values,
          value: _currentMarker.frequency ?? Frequency.cyclical,
          onChanged: (Listable val) {
            setState(
              () => _currentMarker = _updateMarker(frequency: val as Frequency),
            );
          },
        ),
        const SizedBox(height: 16),
        CarbonDropdown(
          label: "Type",
          helperText: "A description of how it feels",
          placeholder: "Select Pain Type",
          items: PainType.values,
          value: _currentMarker.nature ?? PainType.achy,
          onChanged: (Listable val) {
            setState(
              () => _currentMarker = _updateMarker(painType: val as PainType),
            );
          },
        ),
        const SizedBox(height: 16),
        CarbonTextInput(
          label: "Describe what you're feeling (optional)",
          helperText:
              "In your own words — this is what shows up on a symptom report.",
          controller: _descriptionsController,
          maxLines: 3,
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        CarbonTextInput(
          label: "What makes it worse? (optional)",
          controller: _worsensController,
          maxLines: 2,
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        CarbonTextInput(
          label: "What makes it better? (optional)",
          controller: _improvesController,
          maxLines: 2,
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        CarbonTextInput(
          label: "Treatment (optional)",
          helperText: "What are you doing to treat this?",
          controller: _interventionsController,
          maxLines: 2,
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        // Logging a symptom is the moment it's most top-of-mind — asking what the
        // patient plans to do about it now (rather than only offering care advice
        // later, during a days-on follow-up check-in) also means the record reflects
        // their stated intent even when they choose to do nothing yet.
        CarbonDropdown<SymptomCarePlan>(
          label: "What do you want to do about this?",
          helperText:
              "Choosing to get help opens that right away — no need to also tap Save",
          placeholder: "Choose what you'd like to do",
          items: SymptomCarePlan.values,
          value: _currentMarker.carePlan ?? SymptomCarePlan.keepCheckingIn,
          onChanged: (Listable val) => _selectCarePlan(val as SymptomCarePlan),
        ),
        const SizedBox(height: 24),
        CarbonCompactButton(
          icon: Symbols.check,
          label: "Save",
          style: CarbonButtonStyle.primary,
          onTap: () {
            // Picking up whatever's currently typed — the text controllers are never
            // synced into _currentMarker until here (see _updateMarker), since we
            // don't want a setState/rebuild firing on every keystroke.
            widget.onSave(_updateMarker());
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // Asks why, but doesn't insist on an answer beyond the sensible default already
  // selected — a single tap on Remove always carries a real reason, nobody is forced
  // to deliberate over the list first. Cancel backs out to the form with nothing lost.
  Widget _buildDismissConfirmation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Remove ${_currentMarker.name}?",
          style: CarbonTheme.carbonHeadingTextStyle,
        ),
        const SizedBox(height: 16),
        RadioGroup<SymptomDismissalReason>(
          groupValue: _dismissalReason,
          onChanged: (val) =>
              setState(() => _dismissalReason = val ?? _dismissalReason),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final reason in SymptomDismissalReason.values)
                RadioListTile<SymptomDismissalReason>(
                  value: reason,
                  activeColor: carbonColorButtonPrimary,
                  title: Text(reason.label, style: CarbonTheme.carbonTextStyle),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarbonCompactButton(
          icon: Symbols.delete,
          label: "Remove",
          style: CarbonButtonStyle.danger,
          onTap: () {
            widget.onDismiss(_currentMarker, _dismissalReason);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 8),
        CarbonCompactButton(
          icon: Symbols.arrow_back,
          label: "Cancel",
          style: CarbonButtonStyle.ghost,
          onTap: () => setState(() => _confirmingDismiss = false),
        ),
      ],
    );
  }

  // Someone choosing "seek immediate help" or "call 911" while in pain shouldn't have
  // to also find and tap a separate Save button to actually get there — the four
  // action-requiring plans hand off the moment they're picked. The two passive plans
  // (ignore for now / keep checking in) still just record the choice and wait for Save,
  // since there's nowhere else to go.
  void _selectCarePlan(SymptomCarePlan plan) {
    final updated = _updateMarker(carePlan: plan);
    setState(() => _currentMarker = updated);
    if (plan.requiresImmediateAction) {
      widget.onSave(_currentMarker);
      Navigator.pop(context);
      widget.onSeekCare(_currentMarker, plan);
    }
  }

  // Each call only supplies the field the user just changed — everything else must
  // carry forward from _currentMarker's current state, or every prior selection gets
  // silently wiped by the next one (this was the actual bug before: frequency/nature
  // were accepted as parameters here but never read).
  BodyMarker _updateMarker({
    DetailedPainLevel? severity,
    Frequency? frequency,
    PainType? painType,
    SymptomCarePlan? carePlan,
  }) {
    return BodyMarker(
      id: _currentMarker.id,
      offset: _currentMarker.offset,
      emoji: _currentMarker.emoji,
      name: _currentMarker.name,
      medicalName: _currentMarker.medicalName,
      zoneMap: _currentMarker.zoneMap,
      group: _currentMarker.group,
      severity: severity ?? _currentMarker.severity,
      frequency: frequency ?? _currentMarker.frequency,
      nature: painType ?? _currentMarker.nature,
      carePlan: carePlan ?? _currentMarker.carePlan,
      // Always read live off the controllers, not _currentMarker — these fields have
      // no onChanged/setState wiring (typing shouldn't fight the dropdowns' own
      // rebuilds), so _currentMarker itself never carries the latest keystrokes.
      descriptions: _textOrNull(_descriptionsController),
      improvesWhen: _textOrNull(_improvesController),
      worsensWhen: _textOrNull(_worsensController),
      interventionsTried: _textOrNull(_interventionsController),
      recorded: _currentMarker.recorded,
      resolved: _currentMarker.resolved,
      resolvedAt: _currentMarker.resolvedAt,
      lastCheckedAt: _currentMarker.lastCheckedAt,
    );
  }

  String? _textOrNull(TextEditingController controller) {
    final String trimmed = controller.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
