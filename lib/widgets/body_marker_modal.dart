import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/classes/patient_pain.dart';
import 'package:triage/widgets/carbon_button_compact.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';

import '../classes/body_markers.dart';
import '../classes/listable.dart';

class BodyMarkerModal extends StatefulWidget {
  final BodyMarker initialMarker;
  final Function(BodyMarker) onSave;

  const BodyMarkerModal({super.key, required this.initialMarker, required this.onSave});

  @override
  State<BodyMarkerModal> createState() => _BodyMarkerModalState();
}

class _BodyMarkerModalState extends State<BodyMarkerModal> {
  late BodyMarker _currentMarker;

  @override
  void initState() {
    super.initState();
    _currentMarker = widget.initialMarker;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentMarker.name.toUpperCase(), style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 16),

            CarbonButton2LineDropDown<DetailedPainLevel>(
              label: "Pain Level",
              placeholder: "Select the Pain Level",
              helperText: "Choose the level of pain that you are feeling",
              onChanged: (Listable val) {
                setState(() => _currentMarker = _updateMarker(severity: val as DetailedPainLevel));
              },
              value: _currentMarker.severity ?? DetailedPainLevel.none,
              items: DetailedPainLevel.values,
            ),
            const SizedBox(height: 16),
            CarbonDropdown<Frequency>(
              label: "Frequency",
              helperText: "Select how often this pain occurs",
              placeholder: "Select the frequency",
              items: Frequency.values,
              value: _currentMarker.frequency ?? Frequency.cyclical,
              onChanged: (Listable val) {
                setState(() => _currentMarker = _updateMarker(frequency: val as Frequency));
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
                setState(() => _currentMarker = _updateMarker(painType: val as PainType));
              },
            ),
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: () {
                widget.onSave(_currentMarker);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Each call only supplies the field the user just changed — everything else must
  // carry forward from _currentMarker's current state, or every prior selection gets
  // silently wiped by the next one (this was the actual bug before: frequency/nature
  // were accepted as parameters here but never read).
  BodyMarker _updateMarker({DetailedPainLevel? severity, Frequency? frequency, PainType? painType}) {
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
      descriptions: _currentMarker.descriptions,
      improvesWhen: _currentMarker.improvesWhen,
      worsensWhen: _currentMarker.worsensWhen,
      interventionsTried: _currentMarker.interventionsTried,
      recorded: _currentMarker.recorded,
      resolved: _currentMarker.resolved,
      resolvedAt: _currentMarker.resolvedAt,
      lastCheckedAt: _currentMarker.lastCheckedAt,
    );
  }
}
