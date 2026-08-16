import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/allergen.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import 'carbon_button_compact.dart';

// A new, Carbon-native chip — deliberately not styled to match InteractionsChip, which
// is raw Material (ActionChip/Badge/StadiumBorder) and separately flagged as technical
// debt, not something to extend rather than fix. This is new code, so it starts Carbon
// from day one instead of matching a bad precedent.
class AllergyConflictChip extends StatelessWidget {
  final String medicationName;
  final List<AllergyConflict> conflicts;

  const AllergyConflictChip({super.key, required this.medicationName, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();
    final String label = conflicts.length == 1
        ? "Possible allergy: ${conflicts.first.allergenName}"
        : "Possible allergies (${conflicts.length})";

    return InkWell(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: carbonColorSupportError.withValues(alpha: 0.1),
          border: Border.all(color: carbonColorSupportError),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.warning, size: 14, color: carbonColorSupportError),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: carbonColorSupportError, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Possible Allergy Match", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 8),
              Text(
                "This is a name match, not a clinical review. Confirm with your pharmacist or doctor before "
                "assuming anything is safe or unsafe based on it.",
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              const SizedBox(height: 12),
              ...conflicts.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Symbols.warning, color: carbonColorSupportError),
                  title: Text('$medicationName ~ ${c.allergenName}', style: CarbonTheme.carbonLabelTextStyle),
                  subtitle: Text('Recorded severity: ${c.severity.label}', style: CarbonTheme.carbonHelperTextStyle),
                ),
              ),
              const SizedBox(height: 8),
              CarbonCompactButton(
                icon: Symbols.check,
                label: "Got It",
                style: CarbonButtonStyle.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
