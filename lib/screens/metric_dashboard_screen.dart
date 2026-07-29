import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/database_manager.dart';
import '../app_theme.dart';
import '../classes/patient.dart';
import '../widgets/metric_tracking_card.dart';

class MetricsDashboardScreen extends StatefulWidget {
  final Patient user;
  const MetricsDashboardScreen({super.key, required this.user});

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  late Future<Map<String, dynamic>> _metricsDataFuture;

  @override
  void initState() {
    super.initState();
    _loadMetricsData();
  }

  void _loadMetricsData() {
    _metricsDataFuture = _fetchAllMetricsData();
  }

  Future<Map<String, dynamic>> _fetchAllMetricsData() async {
    final dbManager = DatabaseManager();
    final userUuid = widget.user.patientUuid;

    // Retrieve and convert queries into growable, modifiable lists
    final rawMetrics = await dbManager.getAllMetrics();
    final List<Map<String, dynamic>> allMetrics = rawMetrics.map((e) => Map<String, dynamic>.from(e)).toList();

    final rawTracked = await dbManager.getTrackedMetrics(userUuid);
    final List<Map<String, dynamic>> trackedMetrics = rawTracked.map((e) => Map<String, dynamic>.from(e)).toList();

    final rawValues = await dbManager.getPatientMetricValues(userUuid);
    final List<Map<String, dynamic>> allValues = rawValues.map((e) => Map<String, dynamic>.from(e)).toList();

    final Set<String> trackedMetricIds = trackedMetrics.map((m) => (m['metric_id'] ?? m['id']).toString()).toSet();

    // Group values by metric_id for fast hydration upon expansion
    final Map<String, List<Map<String, dynamic>>> valuesByMetricId = {};
    for (var valMap in allValues) {
      final metricId = (valMap['metric_id'] ?? '').toString();
      if (metricId.isNotEmpty) {
        valuesByMetricId.putIfAbsent(metricId, () => []).add(valMap);
      }
    }

    // Map tracked configuration settings by metric_id
    final Map<String, Map<String, dynamic>> trackedConfigByMetricId = {};
    for (var tMap in trackedMetrics) {
      final metricId = (tMap['metric_id'] ?? tMap['id']).toString();
      if (metricId.isNotEmpty) {
        trackedConfigByMetricId[metricId] = tMap;
      }
    }

    // Sort cards safely now that allMetrics is a modifiable growable list
    allMetrics.sort((a, b) {
      final aId = (a['id'] ?? '').toString();
      final bId = (b['id'] ?? '').toString();
      final aTracked = trackedMetricIds.contains(aId) ? 0 : 1;
      final bTracked = trackedMetricIds.contains(bId) ? 0 : 1;
      return aTracked.compareTo(bTracked);
    });

    return {
      'allMetrics': allMetrics,
      'trackedMetricIds': trackedMetricIds,
      'valuesByMetricId': valuesByMetricId,
      'trackedConfigByMetricId': trackedConfigByMetricId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Metrics"), backgroundColor: carbonColorScaffoldBackground),
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _metricsDataFuture,
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

          final data = snapshot.data ?? {};
          final List<Map<String, dynamic>> allMetrics = data['allMetrics'] ?? [];
          final Set<String> trackedMetricIds = data['trackedMetricIds'] ?? {};
          final Map<String, List<Map<String, dynamic>>> valuesByMetricId = data['valuesByMetricId'] ?? {};
          final Map<String, Map<String, dynamic>> trackedConfigByMetricId = data['trackedConfigByMetricId'] ?? {};

          if (allMetrics.isEmpty) {
            return Center(
              child: Text("No metric definitions found.", style: TextStyle(color: Colors.grey.shade600)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            itemCount: allMetrics.length,
            itemBuilder: (context, index) {
              final metric = allMetrics[index];
              final metricId = (metric['id'] ?? '').toString();
              final isTracked = trackedMetricIds.contains(metricId);
              final historicalValues = valuesByMetricId[metricId] ?? [];
              final config = trackedConfigByMetricId[metricId] ?? {};

              return MetricExpandableCard(
                title: metric['name'] ?? 'Unknown Metric',
                description: metric['description'] ?? 'No description provided.',
                whyItMatters: metric['why_it_matters'] ?? 'Clinically relevant to your health journey baseline.',
                categoryIcon: Symbols.monitoring,
                isInitiallyTracked: isTracked,
                historicalValues: historicalValues,
                savedConfig: config,
              );
            },
          );
        },
      ),
    );
  }
}
