import 'dart:convert';

import 'package:flutter/services.dart';

import 'listable.dart';

// Replaces the old "Link Journey Support" dropdown (JourneySupports enum) — that
// concept had no real meaning here and its onChanged callback was a no-op, never
// persisted anywhere. What actually matters to a doctor reading this data: how was
// this number captured — an automatic device or a manual observation — since a
// Blood Pressure reading from an Omron differs in reliability from one taken by
// manual cuff, and that context is exactly what's missing today.
enum MetricSourceType implements Listable {
  observation,
  device;

  @override
  String get label {
    switch (this) {
      case MetricSourceType.observation:
        return "Observation";
      case MetricSourceType.device:
        return "Device";
    }
  }

  @override
  String get description {
    switch (this) {
      case MetricSourceType.observation:
        return "Measured or noted by hand — a test strip, a manual count, a visual check";
      case MetricSourceType.device:
        return "Captured by a piece of equipment — a monitor, meter, or wearable";
    }
  }
}

// Reference-only catalog (no DB seeding needed — nothing patient-specific to join
// against, just a static suggestion list), same pattern as ImmunizationService's
// direct asset load rather than the heavier DB-catalog approach Tests/Supplies use
// for their condition-linked suggestions.
class MetricSourceCatalog {
  static Map<String, dynamic>? _data;

  static Future<Map<String, dynamic>> _load() async {
    if (_data != null) return _data!;
    final String raw = await rootBundle.loadString(
      'assets/metrics/metric_sources.json',
    );
    _data = jsonDecode(raw) as Map<String, dynamic>;
    return _data!;
  }

  static Future<List<String>> devicesFor(String category) async {
    final data = await _load();
    final categories = data['categories'] as Map<String, dynamic>? ?? {};
    final entry = categories[category] as Map<String, dynamic>?;
    final List<String> devices =
        (entry?['devices'] as List?)?.cast<String>() ?? [];
    if (devices.isNotEmpty) return devices;
    return (data['defaultDevices'] as List?)?.cast<String>() ?? [];
  }

  static Future<List<String>> observationsFor(String category) async {
    final data = await _load();
    final categories = data['categories'] as Map<String, dynamic>? ?? {};
    final entry = categories[category] as Map<String, dynamic>?;
    final List<String> observations =
        (entry?['observations'] as List?)?.cast<String>() ?? [];
    if (observations.isNotEmpty) return observations;
    return (data['defaultObservations'] as List?)?.cast<String>() ?? [];
  }

  // The full, unfiltered lists — for the picker sheet's "browse everything" section,
  // in case the smart per-category suggestion doesn't have what the patient is using.
  static Future<List<String>> allDevices() async {
    final data = await _load();
    final categories = data['categories'] as Map<String, dynamic>? ?? {};
    final Set<String> all = {};
    for (final entry in categories.values) {
      all.addAll(
        ((entry as Map<String, dynamic>)['devices'] as List?)?.cast<String>() ??
            [],
      );
    }
    all.addAll((data['defaultDevices'] as List?)?.cast<String>() ?? []);
    return all.toList()..sort();
  }

  static Future<List<String>> allObservations() async {
    final data = await _load();
    final categories = data['categories'] as Map<String, dynamic>? ?? {};
    final Set<String> all = {};
    for (final entry in categories.values) {
      all.addAll(
        ((entry as Map<String, dynamic>)['observations'] as List?)
                ?.cast<String>() ??
            [],
      );
    }
    all.addAll((data['defaultObservations'] as List?)?.cast<String>() ?? []);
    return all.toList()..sort();
  }
}

// What's actually persisted per tracked metric.
class MetricSourceSelection {
  final MetricSourceType? source;
  final String? sourceDetail;

  const MetricSourceSelection({this.source, this.sourceDetail});

  factory MetricSourceSelection.fromMap(Map<String, dynamic> row) {
    final String? rawSource = row['source'] as String?;
    return MetricSourceSelection(
      source: rawSource == null
          ? null
          : MetricSourceType.values.firstWhere(
              (s) => s.name == rawSource,
              orElse: () => MetricSourceType.observation,
            ),
      sourceDetail: row['source_detail'] as String?,
    );
  }
}
