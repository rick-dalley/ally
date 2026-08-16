import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/widgets/carbon_style_search_field.dart';
import '../app_theme.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/metric_source.dart';
import '../classes/metric_value.dart';
import '../classes/patient.dart';
import '../widgets/dual_bound_capsule.dart';
import '../widgets/metric_tracking_card.dart';

class MetricsDashboardScreen extends StatefulWidget {
  final Patient user;
  final Function(Patient) onVitalsUpdate;
  final Function(Patient) onMemberUpdate;
  const MetricsDashboardScreen({
    super.key,
    required this.user,
    required this.onVitalsUpdate(Patient patient),
    required this.onMemberUpdate,
  });

  @override
  State<MetricsDashboardScreen> createState() => MetricsDashboardScreenState();
}

class MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  late Future<void> initDataFuture;
  late PatientController patientController;
  final TextEditingController searchController = TextEditingController();
  late final userUuid = widget.user.patientUuid;
  String searchQuery = '';

  Map<int, Metric> allMetrics = {};
  Map<int, Metric> trackedMetrics = {};
  Map<int, Metric> untrackedMetrics = {};
  Map<int, MetricRange> ranges = {};
  Map<int, MetricThreshold> thresholds = {};
  Map<int, MetricTarget> targets = {};
  Map<int, bool> onDashboard = {};
  Map<int, MetricSourceSelection> sources = {};
  Map<int, MetricReminderPreference> reminderPreferences = {};

  @override
  void initState() {
    super.initState();
    initDataFuture = loadDataOnce();
    patientController = PatientController(widget.user);
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
    thresholds = await metrics.getThresholdsFor(userUuid);
    targets = await metrics.getTargetsFor(userUuid);
    onDashboard = metrics.onDashboard;
    sources = metrics.sources;
    reminderPreferences = await metrics.getReminderPreferencesFor(userUuid);
    await metrics.loadHistoryFor(userUuid);
  }

  // Re-fetches threshold/target/range/history and rebuilds — called after any save from
  // inside a card (threshold, target, or a new reading). Range and history need a fresh
  // round trip too, not just thresholds/targets — a newly-saved reading changes both, and
  // the card itself can't reflect that on its own (its `range`/`history` are getters over
  // widget.range/widget.historicalValues, so the parent handing back fresh data is what
  // actually makes a new reading show up).
  Future<void> _reloadMetricData() async {
    final metrics = Metrics();
    metrics.tracked = trackedMetrics;
    final freshThresholds = await metrics.getThresholdsFor(userUuid);
    final freshTargets = await metrics.getTargetsFor(userUuid);
    final freshRanges = await metrics.getRangesFor(userUuid);
    final freshSources = await metrics.getSourcesFor(userUuid);
    final freshReminderPreferences = await metrics.getReminderPreferencesFor(
      userUuid,
    );
    await metrics.loadHistoryFor(userUuid);
    if (!mounted) return;
    setState(() {
      thresholds = freshThresholds;
      targets = freshTargets;
      ranges = freshRanges;
      sources = freshSources;
      reminderPreferences = freshReminderPreferences;
    });
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
          // Untracking deletes the patient_metric_tracking row outright (see
          // DatabaseManager.deleteTrackingMetric), which carries on_dashboard with it —
          // drop it locally too so a re-tracked metric doesn't appear to still be
          // dashboard-checked from stale in-memory state.
          onDashboard.remove(metricId);
          Metrics.stopTrackingMetric(metricId: metricId, patientUuid: userUuid);
        }
      }
    });
  }

  void handleDashboardChanged(int metricId, bool isOnDashboard) {
    setState(() => onDashboard[metricId] = isOnDashboard);
    Metrics.setOnDashboard(
      metricId: metricId,
      patientUuid: userUuid,
      onDashboard: isOnDashboard,
    );
  }

  // The summary strip for whichever tracked metrics the patient has checked "Show on
  // Dashboard" for on their card — deliberately not every tracked metric, so this stays
  // a curated at-a-glance row rather than growing to match the full tracked list.
  // Unlike the per-card capsule (Safe tier only), each tile here nests Safe around
  // Healthy so both boundary sets are visible together, per Richard's spec.
  Widget _buildDashboardPanel() {
    final List<Metric> selected =
        trackedMetrics.values.where((m) => onDashboard[m.id] == true).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (selected.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: selected.map((metric) {
            final MetricThreshold? threshold = thresholds[metric.id];
            final MetricRange? range = ranges[metric.id];
            final double safeMin =
                threshold?.dangerLow ?? metric.safeLowerValue ?? 0.0;
            final double safeMax =
                threshold?.dangerHigh ?? metric.safeUpperValue ?? 0.0;
            final double healthyMin =
                threshold?.healthyLow ?? metric.healthyLowerValue ?? 0.0;
            final double healthyMax =
                threshold?.healthyHigh ?? metric.healthyUpperValue ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: carbonColorBorderSubtle00),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      metric.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CarbonTheme.carbonLabelTextStyle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DualBoundCapsule(
                    current: range?.latest ?? 0.0,
                    historicalMin: range?.minimum ?? 0.0,
                    historicalMax: range?.maximum ?? 0.0,
                    healthyMin: healthyMin,
                    healthyMax: healthyMax,
                    safeMin: safeMin,
                    safeMax: safeMax,
                    height: 70,
                    color: carbonColorPrimary04,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // A completely separate, clean async routine to fetch fresh row data
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<void>(
        future: initDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
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
              child: Text(
                "No metric definitions found.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final filteredTrackedList =
              trackedMetrics.values.where((metric) {
                if (searchQuery.isEmpty) return true;

                final name = metric.name.toLowerCase();
                final description = metric.category.toLowerCase();
                final searchTerms = metric.searchTerms ?? [];

                if (name.contains(searchQuery) ||
                    description.contains(searchQuery)) {
                  return true;
                }

                return searchTerms.any(
                  (term) => term.toLowerCase().contains(searchQuery),
                );
              }).toList()..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

          final filteredUntrackedList =
              untrackedMetrics.values.where((metric) {
                if (searchQuery.isEmpty) return true;

                final name = metric.name.toLowerCase();
                final description = metric.category.toLowerCase();
                final searchTerms = metric.searchTerms ?? [];

                if (name.contains(searchQuery) ||
                    description.contains(searchQuery)) {
                  return true;
                }

                return searchTerms.any(
                  (term) => term.toLowerCase().contains(searchQuery),
                );
              }).toList()..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

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
                    _buildDashboardPanel(),
                    if (filteredTrackedList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          "Tracked Metrics",
                          style: CarbonTheme.carbonTextStyle,
                        ),
                      ),
                      for (final metric in filteredTrackedList)
                        MetricExpandableCard(
                          key: ValueKey(metric.id),
                          patientUuid: userUuid,
                          tracked: true,
                          metric: metric,
                          range:
                              ranges[metric.id] ??
                              MetricRange(
                                id: metric.id,
                                maximum: 0,
                                minimum: 0,
                              ),
                          threshold: thresholds[metric.id],
                          target: targets[metric.id],
                          description: metric.description,
                          whyItMatters: metric.purpose ?? '',
                          categoryIcon: Symbols.monitoring,
                          historicalValues: metric.history.values
                              .map((v) => v.toMap())
                              .toList(),
                          savedConfig: const {},
                          onTrackingChanged: (isTracked) {
                            handleTrackingChanged(metric.id, isTracked);
                          },
                          onDataChanged: _reloadMetricData,
                          onDashboard: onDashboard[metric.id] ?? false,
                          onDashboardChanged: (isOnDashboard) {
                            handleDashboardChanged(metric.id, isOnDashboard);
                          },
                          source: sources[metric.id],
                          reminderPreference:
                              reminderPreferences[metric.id] ??
                              const MetricReminderPreference(),
                        ),
                    ],
                    if (filteredUntrackedList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          "Available Metrics",
                          style: CarbonTheme.carbonTextStyle,
                        ),
                      ),
                      for (final metric in filteredUntrackedList)
                        MetricExpandableCard(
                          key: ValueKey(metric.id),
                          patientUuid: userUuid,
                          tracked: false,
                          metric: metric,
                          threshold: thresholds[metric.id],
                          target: targets[metric.id],
                          description: metric.description,
                          whyItMatters: metric.purpose ?? '',
                          categoryIcon: Symbols.monitoring,
                          historicalValues: metric.history.values
                              .map((v) => v.toMap())
                              .toList(),
                          savedConfig: const {},
                          onTrackingChanged: (isTracked) {
                            handleTrackingChanged(metric.id, isTracked);
                          },
                          onDataChanged: _reloadMetricData,
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
