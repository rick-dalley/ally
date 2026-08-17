import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/metric_source.dart';
import 'package:carbon_ui/widgets/carbon_quick_entry_field.dart';
import 'package:carbon_ui/widgets/carbon_style_action_tile.dart';
import 'package:carbon_ui/widgets/carbon_style_search_field.dart';

// Picking a device or observation method for a tracked metric — mirrors
// SupplyCatalogPickerSheet/TestCatalogPickerSheet's shape (quick-entry for something
// not on the list, a curated "suggested for this metric" section, then the full
// catalog filtered live by the search field) rather than inventing a new pattern.
class MetricSourcePickerSheet extends StatefulWidget {
  final MetricSourceType sourceType;
  final String metricCategory;
  final String patientUuid;
  final int metricId;

  const MetricSourcePickerSheet({
    super.key,
    required this.sourceType,
    required this.metricCategory,
    required this.patientUuid,
    required this.metricId,
  });

  @override
  State<MetricSourcePickerSheet> createState() =>
      _MetricSourcePickerSheetState();
}

class _MetricSourcePickerSheetState extends State<MetricSourcePickerSheet> {
  late Future<List<String>> _yourDevicesFuture;
  late Future<List<String>> _suggestedFuture;
  late Future<List<String>> _allFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  bool get _isDevice => widget.sourceType == MetricSourceType.device;

  @override
  void initState() {
    super.initState();
    _yourDevicesFuture = _isDevice
        ? DatabaseManager().getDeviceNamesForMetric(
            patientUuid: widget.patientUuid,
            metricId: widget.metricId,
          )
        : Future.value(const []);
    _suggestedFuture = _isDevice
        ? MetricSourceCatalog.devicesFor(widget.metricCategory)
        : MetricSourceCatalog.observationsFor(widget.metricCategory);
    _allFuture = _isDevice
        ? MetricSourceCatalog.allDevices()
        : MetricSourceCatalog.allObservations();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _choose(String name) => Navigator.pop(context, name);

  @override
  Widget build(BuildContext context) {
    final String title = _isDevice ? "Which device?" : "How was this observed?";
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
            Text(title, style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 16),
            CarbonQuickEntryField(
              label: "Don't see it below?",
              hintText: _isDevice
                  ? "Type the device and tap the check"
                  : "Type how it was measured",
              onSave: (name) async => _choose(name),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<String>>(
              future: _yourDevicesFuture,
              builder: (context, snapshot) {
                final mine = snapshot.data ?? const [];
                if (mine.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Devices you've used for this",
                      style: CarbonTheme.carbonLabelTextStyle,
                    ),
                    const SizedBox(height: 8),
                    ...mine.map(
                      (name) => CarbonActionTile(
                        icon: Symbols.history,
                        title: name,
                        onTap: () => _choose(name),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            FutureBuilder<List<String>>(
              future: _suggestedFuture,
              builder: (context, snapshot) {
                final suggested = snapshot.data ?? const [];
                if (suggested.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Suggested for this metric",
                      style: CarbonTheme.carbonLabelTextStyle,
                    ),
                    const SizedBox(height: 8),
                    ...suggested.map(
                      (name) => CarbonActionTile(
                        icon: _isDevice
                            ? Symbols.devices_other
                            : Symbols.visibility,
                        title: name,
                        onTap: () => _choose(name),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            Text("Full list", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 8),
            CarbonSearchField(controller: _searchController, label: "Search"),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _allFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final all = snapshot.data ?? const [];
                final filtered = _query.isEmpty
                    ? all
                    : all
                          .where((n) => n.toLowerCase().contains(_query))
                          .toList();
                if (filtered.isEmpty) {
                  return Text(
                    "No matches.",
                    style: CarbonTheme.carbonHelperTextStyle,
                  );
                }
                return Column(
                  children: filtered
                      .map(
                        (name) => CarbonActionTile(
                          icon: _isDevice
                              ? Symbols.devices_other
                              : Symbols.visibility,
                          title: name,
                          onTap: () => _choose(name),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
