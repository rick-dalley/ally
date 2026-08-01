import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/widgets/carbon_style_search_field.dart';
import '../app_theme.dart';
import '../classes/metric_value.dart';
import '../classes/patient.dart';
import '../widgets/metric_tracking_card.dart';

class MetricsDashboardScreen extends StatefulWidget {
  final Patient user;
  const MetricsDashboardScreen({super.key, required this.user});

  @override
  State<MetricsDashboardScreen> createState() => MetricsDashboardScreenState();
}

class MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  late Future<void> initDataFuture;
  final TextEditingController searchController = TextEditingController();
  late final userUuid = widget.user.patientUuid;
  String searchQuery = '';

  Map<int, Metric> allMetrics = {};
  Map<int, Metric> trackedMetrics = {};
  Map<int, Metric> untrackedMetrics = {};
  Map<int, MetricRange> ranges = {};
  @override
  void initState() {
    super.initState();
    initDataFuture = loadDataOnce();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDataOnce() async {
    Metrics metrics = await Metrics.forPatient(userUuid);
    allMetrics = metrics.all;
    trackedMetrics = metrics.tracked;
    untrackedMetrics = metrics.untracked;
    ranges = await metrics.getRangesFor(userUuid);
  }

  void handleTrackingChanged(int metricId, bool isTracked) {
    setState(() {
      if (isTracked) {
        final metric = untrackedMetrics.remove(metricId);
        if (metric != null) {
          trackedMetrics[metricId] = metric;
          Metrics.trackMetric(metricId: metricId, patientUuid: userUuid);
        }
      } else {
        final metric = trackedMetrics.remove(metricId);
        if (metric != null) {
          untrackedMetrics[metricId] = metric;
          Metrics.stopTrackingMetric(metricId: metricId, patientUuid: userUuid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<void>(
        future: initDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading metrics:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            );
          }

          if (allMetrics.isEmpty) {
            return Center(
              child: Text("No metric definitions found.", style: TextStyle(color: Colors.grey.shade600)),
            );
          }

          final filteredTrackedList = trackedMetrics.values.where((metric) {
            if (searchQuery.isEmpty) return true;

            final name = metric.name.toLowerCase();
            final description = metric.category.toLowerCase();
            final searchTerms = metric.searchTerms ?? [];

            if (name.contains(searchQuery) || description.contains(searchQuery)) {
              return true;
            }

            return searchTerms.any((term) => term.toLowerCase().contains(searchQuery));
          }).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          final filteredUntrackedList = untrackedMetrics.values.where((metric) {
            if (searchQuery.isEmpty) return true;

            final name = metric.name.toLowerCase();
            final description = metric.category.toLowerCase();
            final searchTerms = metric.searchTerms ?? [];

            if (name.contains(searchQuery) || description.contains(searchQuery)) {
              return true;
            }

            return searchTerms.any((term) => term.toLowerCase().contains(searchQuery));
          }).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: CarbonSearchField(controller: searchController),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 90),
                  children: [
                    if (filteredTrackedList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text("Tracked Metrics", style: CarbonTheme.carbonTextStyle),
                      ),
                      for (final metric in filteredTrackedList)
                        MetricExpandableCard(
                          key: ValueKey(metric.id),
                          tracked: true,
                          metric: metric,
                          range: ranges[metric.id] ?? MetricRange(id: metric.id, maximum: 0, minimum: 0),
                          description: metric.description,
                          whyItMatters: metric.purpose ?? '',
                          categoryIcon: Symbols.monitoring,
                          historicalValues: metric.history.values.map((v) => v.toMap()).toList(),
                          savedConfig: const {},
                          onTrackingChanged: (isTracked) {
                            handleTrackingChanged(metric.id, isTracked);
                          },
                        ),
                    ],
                    if (filteredUntrackedList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text("Available Metrics", style: CarbonTheme.carbonTextStyle),
                      ),
                      for (final metric in filteredUntrackedList)
                        MetricExpandableCard(
                          key: ValueKey(metric.id),
                          tracked: false,
                          metric: metric,
                          description: metric.description,
                          whyItMatters: metric.purpose ?? '',
                          categoryIcon: Symbols.monitoring,
                          historicalValues: metric.history.values.map((v) => v.toMap()).toList(),
                          savedConfig: const {},
                          onTrackingChanged: (isTracked) {
                            handleTrackingChanged(metric.id, isTracked);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
