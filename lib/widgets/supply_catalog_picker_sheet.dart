import 'package:flutter/material.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient_supply.dart';
import 'package:carbon_ui/widgets/carbon_quick_entry_field.dart';
import 'package:carbon_ui/widgets/carbon_style_action_tile.dart';

// Step one of tracking a supply: pick from what's suggested by the patient's own
// conditions (condition_supply), browse the full catalog, or type one that's in
// neither — mirrors TestCatalogPickerSheet's shape. Whatever's picked here comes back
// as a draft PatientSupply for the caller to open SupplyDetailSheet against for step
// two (quantity/threshold/medication link), same two-step flow as booking a test.
class SupplyCatalogPickerSheet extends StatefulWidget {
  final String patientUuid;

  const SupplyCatalogPickerSheet({super.key, required this.patientUuid});

  @override
  State<SupplyCatalogPickerSheet> createState() => _SupplyCatalogPickerSheetState();
}

class _SupplyCatalogPickerSheetState extends State<SupplyCatalogPickerSheet> {
  late Future<List<SupplyCatalogEntry>> _suggestedFuture;
  late Future<Map<String, List<SupplyCatalogEntry>>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _suggestedFuture = DatabaseManager()
        .getSuggestedSupplies(widget.patientUuid)
        .then((rows) => rows.map(SupplyCatalogEntry.fromRow).toList());
    _catalogFuture = DatabaseManager().getSupplyCatalog().then((rows) {
      final Map<String, List<SupplyCatalogEntry>> grouped = {};
      for (final row in rows) {
        final entry = SupplyCatalogEntry.fromRow(row);
        grouped.putIfAbsent(entry.category ?? 'Custom', () => []).add(entry);
      }
      return grouped;
    });
  }

  void _choose(String name, String? category) {
    Navigator.pop(context, PatientSupply(name: name, category: category));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          children: [
            Text("Add a Supply", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 16),
            CarbonQuickEntryField(
              label: "Don't see it below?",
              hintText: "Type a supply and tap the check to add it",
              onSave: (name) async {
                _choose(name, 'Custom');
              },
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<SupplyCatalogEntry>>(
              future: _suggestedFuture,
              builder: (context, snapshot) {
                final suggested = snapshot.data ?? const [];
                if (suggested.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Suggested for your conditions", style: CarbonTheme.carbonLabelTextStyle),
                    const SizedBox(height: 8),
                    ...suggested.map(
                      (entry) => CarbonActionTile(
                        icon: entry.icon,
                        iconColor: carbonColorIconInterActive,
                        title: entry.name,
                        subtitle: entry.category,
                        onTap: () => _choose(entry.name, entry.category),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            Text("Full catalog", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, List<SupplyCatalogEntry>>>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final catalog = snapshot.data ?? const {};
                if (catalog.isEmpty) {
                  return Text("Nothing in the catalog yet.", style: CarbonTheme.carbonHelperTextStyle);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: catalog.entries.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(group.key, style: CarbonTheme.carbonHelperTextStyle),
                        ),
                        ...group.value.map(
                          (entry) => CarbonActionTile(
                            icon: entry.icon,
                            iconColor: carbonColorIconInterActive,
                            title: entry.name,
                            onTap: () => _choose(entry.name, entry.category),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
