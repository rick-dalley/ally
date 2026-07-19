import 'package:flutter/material.dart';
import 'package:triage/app_theme.dart';
import 'package:triage/classes/patient_pain.dart';
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
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_currentMarker.name.toUpperCase(), style: AppTheme.carbonTextStyle),
            const SizedBox(height: 16),

            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(PainLevel.none.icon),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(PainLevel.mild.icon),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(PainLevel.distracting.icon),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(PainLevel.limiting.icon),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(PainLevel.incapacitating.icon),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(PainLevel.severe.icon),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // onChanged: ,
            CarbonButton2LineDropDown<DetailedPainLevel>(
              label: "Pain Level",
              placeholder: "Select the Pain Level",
              helperText: "Choose the level of pain that you are feeling",
              onChanged: (Listable val) {
                final level = val as DetailedPainLevel;
                setState(() {
                  _currentMarker = _updateMarker(severity: level);
                });
              },
              value: DetailedPainLevel.none,
              items: DetailedPainLevel.values,
            ),
            const SizedBox(height: 16),
            // Frequency
            CarbonDropdown<Frequency>(
              label: "Frequency",
              helperText: "Select how often this pain occurs",
              placeholder: "Select the frequency",
              items: Frequency.values,
              value: Frequency.cyclical,
              onChanged: (Listable val) {
                setState(() {
                  final Frequency frequency = val as Frequency;
                  _currentMarker = _updateMarker(frequency: frequency);
                });
              },
            ),
            const SizedBox(height: 16),

            // Nature
            CarbonDropdown(
              label: "Type",
              helperText: "A description of how it feels",
              placeholder: "Select Pain Type",
              items: PainType.values,
              value: PainType.achy,
              onChanged: (Listable val) {
                setState(() {
                  PainType painType = val as PainType;
                  _currentMarker = _updateMarker(painType: painType);
                });
              },
            ),

            const Spacer(),
            ElevatedButton(
              onPressed: () {
                widget.onSave(_currentMarker);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to maintain immutability while updating state
  BodyMarker _updateMarker({DetailedPainLevel? severity, Frequency? frequency, PainType? painType}) {
    return BodyMarker(
      offset: _currentMarker.offset,
      emoji: _currentMarker.emoji,
      name: _currentMarker.name,
      medicalName: _currentMarker.medicalName,
      zoneMap: _currentMarker.zoneMap,
      severity: severity,
      group: _currentMarker.group,
    );
  }
}
