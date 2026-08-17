import 'package:flutter/material.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/medical_test.dart';
import 'package:carbon_ui/widgets/carbon_style_action_tile.dart';

// A scrollable list of icon tiles, not a dropdown — Richard's explicit preference, and
// with ~34 entries a dropdown would've buried most of them behind one extra tap anyway
// where a scrollable list lets the icon do some of the recognition work. Reuses
// CarbonActionTile (the same tile already used on the Medical Profile hub) rather than
// a raw ListTile, so this reads as the same component language as the rest of the app.
class TestCatalogPickerSheet extends StatelessWidget {
  final List<TestCatalogEntry> catalog;

  const TestCatalogPickerSheet({super.key, required this.catalog});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Choose a Test", style: CarbonTheme.carbonHeadingTextStyle),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: catalog.length,
                itemBuilder: (context, index) {
                  final entry = catalog[index];
                  return CarbonActionTile(
                    icon: entry.icon,
                    iconColor: carbonColorIconInterActive,
                    title: entry.name,
                    subtitle: entry.category,
                    onTap: () => Navigator.pop(context, entry),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
