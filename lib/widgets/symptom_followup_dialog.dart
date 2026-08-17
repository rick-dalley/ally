import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/body_markers.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'seek_care_sheet.dart';

// Surfaced when the Symptoms screen opens and finds a marker that's old enough to
// check in on. There's no push-notification infrastructure in this app yet, so this
// is the only place a "how's that pain doing?" follow-up can happen — the next time
// the patient actually opens the screen, not a background reminder.
class SymptomFollowUpDialog extends StatelessWidget {
  final String patientUuid;
  final BodyMarker marker;

  const SymptomFollowUpDialog({super.key, required this.patientUuid, required this.marker});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Checking In", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 8),
            Text(
              "A few days ago you mentioned pain in your ${marker.name}. How's it doing now?",
              style: CarbonTheme.carbonHintTextStyle,
            ),
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check_circle,
              label: "It's Better",
              style: CarbonButtonStyle.primary,
              onTap: () async {
                if (marker.id != null) await DatabaseManager().resolveBodyMarker(marker.id!);
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 8),
            CarbonCompactButton(
              icon: Symbols.schedule,
              label: "Still Bothering Me",
              style: CarbonButtonStyle.secondary,
              onTap: () async {
                if (marker.id != null) await DatabaseManager().markBodyMarkerChecked(marker.id!);
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 8),
            CarbonCompactButton(
              icon: Symbols.medical_services,
              label: "I Want to See Someone",
              style: CarbonButtonStyle.ghost,
              onTap: () async {
                if (marker.id != null) await DatabaseManager().markBodyMarkerChecked(marker.id!);
                if (!context.mounted) return;
                Navigator.pop(context, true);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  builder: (context) => SeekCareSheet(
                    patientUuid: patientUuid,
                    bodyPart: marker.name,
                    mode: SeekCareSheetMode.schedule,
                    severity: marker.severity,
                    frequency: marker.frequency,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
