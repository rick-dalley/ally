import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/date_time_utilities.dart';
import 'package:triage/classes/uuid.dart';

import 'package:carbon_ui/interfaces/listable.dart';
import 'medication_services.dart';
import 'metric_source.dart';

// A separate, simpler cadence than FrequencyCodes' Latin dosing vocabulary — that's the
// right fit for "how often is a pill taken," but a metric reading cadence is a different
// concept (weight weekly, glucose several times a day, BP daily) and forcing "Bis in die"
// onto a scale reading would just be borrowed terminology that doesn't fit.
enum MetricReminderCadence implements Listable {
  daily,
  twiceDaily,
  weekly,
  biweekly,
  monthly;

  Duration get interval {
    switch (this) {
      case MetricReminderCadence.daily:
        return const Duration(days: 1);
      case MetricReminderCadence.twiceDaily:
        return const Duration(hours: 12);
      case MetricReminderCadence.weekly:
        return const Duration(days: 7);
      case MetricReminderCadence.biweekly:
        return const Duration(days: 14);
      case MetricReminderCadence.monthly:
        return const Duration(days: 30);
    }
  }

  @override
  // Kept to single-character-ish codes deliberately — the segmented control has 5
  // options in one row, and full words ("Biweekly") wrap to a second line and grow the
  // whole control taller. "2W" rather than "2xW" for biweekly on purpose: "2xW" reads
  // as "twice a week" (more often than weekly), the opposite of what biweekly means
  // here (every 2 weeks, less often than weekly) — same ambiguity "biweekly" itself
  // notoriously has in plain English. The full description (used in the card's summary
  // line, not here) spells it out unambiguously.
  String get label {
    switch (this) {
      case MetricReminderCadence.daily:
        return "D";
      case MetricReminderCadence.twiceDaily:
        return "2xD";
      case MetricReminderCadence.weekly:
        return "W";
      case MetricReminderCadence.biweekly:
        return "2W";
      case MetricReminderCadence.monthly:
        return "M";
    }
  }

  @override
  String get description {
    switch (this) {
      case MetricReminderCadence.daily:
        return "Once a day";
      case MetricReminderCadence.twiceDaily:
        return "Twice a day, roughly 12 hours apart";
      case MetricReminderCadence.weekly:
        return "Once a week";
      case MetricReminderCadence.biweekly:
        return "Once every two weeks";
      case MetricReminderCadence.monthly:
        return "Once a month";
    }
  }
}

// UI-layer bundle, same shape as medication_services.dart's ReminderPreference — not a
// database row, just what the reminder-settings sheet hands back to persist.
class MetricReminderPreference {
  final bool enabled;
  final Set<ReminderChannel> channels;
  final WearableAlertMode? wearableMode;
  final MetricReminderCadence cadence;
  final String? reminderTime; // "HH:mm"

  const MetricReminderPreference({
    this.enabled = false,
    this.channels = const {},
    this.wearableMode,
    this.cadence = MetricReminderCadence.daily,
    this.reminderTime,
  });

  factory MetricReminderPreference.fromMap(Map<String, dynamic>? row) {
    if (row == null) return const MetricReminderPreference();
    final Set<ReminderChannel> channels = {
      if ((row['chime_enabled'] as int? ?? 0) == 1) ReminderChannel.chime,
      if ((row['text_enabled'] as int? ?? 0) == 1) ReminderChannel.text,
      if ((row['email_enabled'] as int? ?? 0) == 1) ReminderChannel.email,
      if ((row['wearable_enabled'] as int? ?? 0) == 1) ReminderChannel.wearable,
    };
    final String? rawMode = row['wearable_mode'] as String?;
    WearableAlertMode? wearableMode;
    if (rawMode != null) {
      for (final mode in WearableAlertMode.values) {
        if (mode.name == rawMode) {
          wearableMode = mode;
          break;
        }
      }
    }
    final String rawCadence =
        (row['cadence'] as String?) ?? MetricReminderCadence.daily.name;
    MetricReminderCadence cadence = MetricReminderCadence.daily;
    for (final c in MetricReminderCadence.values) {
      if (c.name == rawCadence) {
        cadence = c;
        break;
      }
    }
    return MetricReminderPreference(
      enabled: (row['enabled'] as int? ?? 0) == 1,
      channels: channels,
      wearableMode: wearableMode,
      cadence: cadence,
      reminderTime: row['reminder_time'] as String?,
    );
  }
}

// Create a reusable instance

abstract class Storable<T> {
  final String sqlObject;
  const Storable({required this.sqlObject});
  Future<void> insert(T value, String? sqlObject);
  Future<void> update(T value, String? sqlObject);
  Future<void> delete(UUID value, String? sqlObject);
}

abstract class Relatable<T> {
  List<T> get relatedMetricIds;
  void addRelation(UUID metricId);
  void removeRelation(UUID metricId);
}

// 1. Define the conversion function signature
typedef UnitConverter = double Function(double value);

class UnitOfMeasure {
  final String symbol; // e.g., "mmHg", "kPa", "mg/dL"
  final String name; // e.g., "Millimeters of mercury"

  // A map of target unit symbols to their respective conversion functions
  Map<String, UnitConverter> converters = {};

  UnitOfMeasure({
    required this.symbol,
    required this.name,
    required this.converters,
  });

  factory UnitOfMeasure.fromMap(Map<String, dynamic> item) {
    String rawSymbol = item['symbol'] ?? '';
    String rawName = item['name'] ?? '';
    dynamic rawConverters = item['converters'];
    Map<String, UnitConverter> conversionFunctions = {};

    if (rawConverters is Map) {
      rawConverters.forEach((targetSymbol, conversionName) {
        if (conversionName is String) {
          UnitConverter? converter = ConversionRegistry.get(conversionName);
          if (converter != null) {
            conversionFunctions[targetSymbol] = converter;
          }
        }
      });
    }

    return UnitOfMeasure(
      symbol: rawSymbol,
      name: rawName,
      converters: conversionFunctions,
    );
  }

  // Convert this unit to another target unit
  double convertTo(String targetSymbol, double value) {
    final conversionFunction = converters[targetSymbol];
    if (conversionFunction == null) {
      throw UnsupportedError(
        'No conversion path from $symbol to $targetSymbol',
      );
    }
    return conversionFunction(value);
  }
}

class Metric {
  final int id;
  final bool paired;
  final bool isInteger;
  final int? pairId;
  final String name;
  final String category;
  final String description;
  final String? purpose;
  final double? safeUpperValue;
  final double? safeLowerValue;
  final double? healthyUpperValue;
  final double? healthyLowerValue;
  final List<String>? searchTerms;
  Map<UUID, MetricValue> history;
  List<UnitOfMeasure> unitsOfMeasure;

  Metric({
    required this.id,
    required this.name,
    required this.category,
    required this.paired,
    required this.isInteger,
    required this.description,
    this.purpose,
    this.pairId,
    this.safeLowerValue,
    this.safeUpperValue,
    this.healthyLowerValue,
    this.healthyUpperValue,
    this.searchTerms,
  }) : history = {},
       unitsOfMeasure = [];

  factory Metric.fromMap(Map<String, dynamic> items, String category) {
    List<UnitOfMeasure> unitsOfMeasure = [];
    List<String> searchTerms = [];
    dynamic rawSearchTerms = items['search_terms'];
    dynamic rawUoMs = items['units_of_measure'];
    if (rawUoMs != null && rawUoMs is List) {
      for (dynamic rawUoM in rawUoMs) {
        if (rawUoM is Map<String, dynamic>) {
          UnitOfMeasure uom = UnitOfMeasure.fromMap(rawUoM);
          unitsOfMeasure.add(uom);
        }
      }
    }
    if (rawSearchTerms != null && rawSearchTerms is List) {
      for (String term in rawSearchTerms) {
        searchTerms.add(term);
      }
    }
    int pairedWithId = items['pair_id'] ?? 0;
    int rawPaired = items['paired'] ?? 0;
    bool isPaired = pairedWithId != 0 && rawPaired == 1;
    int rawInteger = items['is_integer'] ?? 0;
    Metric metric = Metric(
      id: items['id'] ?? 0,
      name: items['name'] ?? '',
      isInteger: rawInteger == 1,
      paired: isPaired,
      pairId: pairedWithId,
      category: category,
      description: items['description'] ?? '',
      purpose: items['purpose'] ?? '',
      searchTerms: searchTerms,
      safeLowerValue: (items['safe_lower_limit'] as num?)?.toDouble(),
      safeUpperValue: (items['safe_upper_limit'] as num?)?.toDouble(),
      healthyLowerValue: (items['healthy_lower_limit'] as num?)?.toDouble(),
      healthyUpperValue: (items['healthy_upper_limit'] as num?)?.toDouble(),
    );
    metric.unitsOfMeasure = unitsOfMeasure;
    return metric;
  }

  void add(MetricValue value) {
    history[value.id] = value;
  }

  void update(MetricValue value) {
    history[value.id] = value;
  }

  void remove(UUID metricValueId) {
    history.remove(metricValueId);
  }
}

class MetricValue {
  final int metric;
  UUID id = uuid.v4();
  final double value;
  final DateTime recorded;
  final String uom;

  // Standard constructor with named arguments
  MetricValue({
    required this.value,
    required this.recorded,
    required this.uom,
    required this.metric,
  });

  /// Factory constructor to parse database raw maps cleanly
  factory MetricValue.fromMap(Map<String, dynamic> item) {
    // Safely parse the dynamic value column to a double
    final dynamic rawValue = item['metric_value'] ?? item['value'];
    final double parsedValue = (rawValue as num?)?.toDouble() ?? 0.0;
    final String? rawUom = item['uom'];
    final String uomValue = rawUom ?? "";

    // DTUtilities.sqliteToDart's fallback branch handles the UTC-marker correction for
    // a raw SQLite DATETIME string — see that method for why it's needed.
    final dynamic rawDate = item['recorded_at'] ?? item['recorded'];
    final DateTime parsedDate = rawDate != null
        ? DTUtilities.sqliteToDart(rawDate)
        : DateTime.now();

    // `item['metric']` was never a real column on a raw `patient_metric` row (it's
    // `metric_id`) — same "wrong column name, falls through to a hardcoded default"
    // shape as the id/metric_id mix-up already fixed in getRangesFor.
    final int metricId = (item['metric_id'] ?? item['metric']) ?? 0;
    return MetricValue(
      value: parsedValue,
      recorded: parsedDate,
      uom: uomValue,
      metric: metricId,
    );
  }

  /// Converts the model object back into a map structured for SQLite writes
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metric': metric,
      'metric_value': value,
      'recorded_at': recorded
          .toIso8601String(), // Safe string format for database entries
      'uom': uom,
    };
  }
}

class MetricRange {
  final int id;
  late int? count = 0;
  late double? minimum = 0;
  late double? latest = 0;
  late double? maximum = 0;
  late DateTime? measured;

  MetricRange({
    required this.id,
    this.minimum,
    this.maximum,
    this.latest,
    this.measured,
    this.count,
  });

  factory MetricRange.fromMap(Map<String, dynamic> item) {
    int rwId = item["metric_id"] as int? ?? 0;

    // Safely parse numbers whether SQLite returns int or double
    double rwMinimum = (item["min_val"] as num?)?.toDouble() ?? 0.0;
    double rwMaximum = (item["max_val"] as num?)?.toDouble() ?? 0.0;

    // Safely parse count, ensuring it's an int (handling case where it might be returned as num)
    int rwCount = (item["count"] as num?)?.toInt() ?? 0;

    return MetricRange(
      id: rwId,
      minimum: rwMinimum,
      maximum: rwMaximum,
      count: rwCount,
    );
  }
}

// At-least / at-most / exact — a target is a single point to reach or beat, never a
// band to stay inside the way Safe/Healthy are, so it needs a direction to know which
// side of the number counts as "on track" rather than a second bound.
enum TargetDirection {
  atLeast,
  atMost,
  exact;

  String get label {
    switch (this) {
      case TargetDirection.atLeast:
        return "At Least";
      case TargetDirection.atMost:
        return "At Most";
      case TargetDirection.exact:
        return "Exactly";
    }
  }
}

// Doctor-communicated safety/health boundaries for one patient's one metric. This app
// is patient-facing, not something a doctor logs into directly, so these values are
// transcribed by the patient from what their doctor actually told them (same trust
// model as recording a diagnosed condition or a vision prescription) — never a number
// the app or the patient invents on their own. Falls back to the metric catalog's flat
// population defaults when no per-patient override is on file.
class MetricThreshold {
  final int metricId;
  final double? dangerLow;
  final double? dangerHigh;
  final double? healthyLow;
  final double? healthyHigh;
  final String? setBy;
  final DateTime? setAt;

  const MetricThreshold({
    required this.metricId,
    this.dangerLow,
    this.dangerHigh,
    this.healthyLow,
    this.healthyHigh,
    this.setBy,
    this.setAt,
  });

  factory MetricThreshold.fromMap(Map<String, dynamic> item) {
    return MetricThreshold(
      metricId: item['metric_id'] as int,
      dangerLow: (item['danger_low'] as num?)?.toDouble(),
      dangerHigh: (item['danger_high'] as num?)?.toDouble(),
      healthyLow: (item['healthy_low'] as num?)?.toDouble(),
      healthyHigh: (item['healthy_high'] as num?)?.toDouble(),
      setBy: item['set_by'] as String?,
      setAt: item['set_at'] != null
          ? DateTime.tryParse(item['set_at'].toString())
          : null,
    );
  }
}

// A single point the patient (or their trainer) is working toward — VO2 max, target
// weight, resting heart rate. No doctor-authority concept here, unlike MetricThreshold:
// this is a personal goal the patient sets for themselves, not a clinical boundary.
class MetricTarget {
  final int metricId;
  final double targetValue;
  final TargetDirection direction;
  final DateTime? setAt;

  const MetricTarget({
    required this.metricId,
    required this.targetValue,
    required this.direction,
    this.setAt,
  });

  factory MetricTarget.fromMap(Map<String, dynamic> item) {
    return MetricTarget(
      metricId: item['metric_id'] as int,
      targetValue: (item['target_value'] as num).toDouble(),
      direction: TargetDirection.values[item['direction'] as int? ?? 0],
      setAt: item['set_at'] != null
          ? DateTime.tryParse(item['set_at'].toString())
          : null,
    );
  }
}

class Metrics {
  Map<int, Metric> tracked = {};
  Map<int, Metric> untracked = {};
  Map<int, Metric> all = {};
  // Which tracked metrics the patient has checked to show in the summary top panel —
  // a subset of `tracked` (deliberately not everything tracked, so the panel doesn't
  // get cluttered with every metric the patient happens to log).
  Map<int, bool> onDashboard = {};
  // How each tracked metric's readings are actually being captured — device vs.
  // observation, and which device — see MetricSourceSelection.
  Map<int, MetricSourceSelection> sources = {};

  Metrics();

  /// Asynchronous factory to fully hydrate the Metrics object before returning it
  static Future<Metrics> forPatient(String patientUuid) async {
    final metrics = Metrics();
    await metrics.initialize();
    await metrics.buildMapsFor(patientUuid);
    return metrics;
  }

  Future<void> initialize() async {
    final rawList = await DatabaseManager().getAllMetrics();
    all.clear();
    for (var rawMetric in rawList) {
      // Metric.fromMap takes category as a separate param rather than reading it off
      // `items` itself — the one call site here was passing a hardcoded "", so
      // Metric.category was silently empty for every metric ever loaded from the DB,
      // despite the real category sitting right there in the row already.
      Metric metric = Metric.fromMap(rawMetric, rawMetric['category'] ?? '');
      all[metric.id] = metric;
    }
  }

  Future<void> buildMapsFor(String patientUuid) async {
    final rawTracked = await DatabaseManager().getTrackedMetrics(patientUuid);
    tracked.clear();
    untracked.clear();
    onDashboard.clear();
    sources.clear();

    for (Map<String, dynamic> rawMetric in rawTracked) {
      int metricId = rawMetric['metric_id'] ?? rawMetric['id'];
      Metric? metric = all[metricId];
      if (metric != null) {
        tracked[metric.id] = metric;
        onDashboard[metric.id] = (rawMetric['on_dashboard'] as int?) == 1;
        sources[metric.id] = MetricSourceSelection.fromMap(rawMetric);
      }
    }

    all.forEach((k, v) {
      if (!tracked.containsKey(k)) {
        untracked[k] = v;
      }
    });
  }

  Future<Map<int, Metric>> getTrackedMetricsFor(
    String patientUuid,
    bool refresh,
  ) async {
    if (refresh) {
      await buildMapsFor(patientUuid);
    }
    return tracked;
  }

  Future<Map<int, Metric>> getUntrackedMetricsFor(
    String patientUuid,
    bool refresh,
  ) async {
    if (refresh) {
      await buildMapsFor(patientUuid);
    }
    return untracked;
  }

  Future<Map<int, MetricRange>> getRangesFor(String patientUuid) async {
    dynamic rawRanges = await DatabaseManager().getPatientMetricRanges(
      patientUuid,
    );
    dynamic rawRecent = await DatabaseManager().getRecentPatientMetrics(
      patientUuid,
    );
    Map<int, MetricRange> range = {};
    for (dynamic rng in rawRanges) {
      MetricRange metricRange = MetricRange.fromMap(rng);
      range[metricRange.id] = metricRange;
    }
    for (dynamic recent in rawRecent) {
      // `recent['id']` is the reading's own UUID primary key, not the metric's integer
      // catalog id `range` is keyed by — that mismatch (int id = a UUID string) threw
      // immediately once patient_metric actually had rows to return, which it never did
      // before insertPatientMetricReading existed. `metric_id` is the right column.
      int id = recent['metric_id'] as int;
      double latest = (recent['value'] as num).toDouble();
      String rawDate = recent['measured'];
      DateTime measured = DTUtilities.sqliteToDart(rawDate);
      if (range[id] != null) {
        range[id]?.measured = measured;
        range[id]?.latest = latest;
      }
    }
    return range;
  }

  Future<Map<int, MetricThreshold>> getThresholdsFor(String patientUuid) async {
    final rows = await DatabaseManager().getActiveThresholds(patientUuid);
    return {
      for (final row in rows)
        row['metric_id'] as int: MetricThreshold.fromMap(row),
    };
  }

  // Independent of buildMapsFor so a save inside a card can refresh just this, the same
  // way getThresholdsFor/getTargetsFor above do, without a full tracked/untracked rebuild.
  Future<Map<int, MetricSourceSelection>> getSourcesFor(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getTrackedMetrics(patientUuid);
    return {
      for (final row in rows)
        (row['metric_id'] ?? row['id']) as int: MetricSourceSelection.fromMap(
          row,
        ),
    };
  }

  Future<Map<int, MetricReminderPreference>> getReminderPreferencesFor(
    String patientUuid,
  ) async {
    final rows = await DatabaseManager().getAllMetricReminderPreferences(
      patientUuid,
    );
    return {
      for (final row in rows)
        row['metric_id'] as int: MetricReminderPreference.fromMap(row),
    };
  }

  Future<Map<int, MetricTarget>> getTargetsFor(String patientUuid) async {
    final rows = await DatabaseManager().getActiveTargets(patientUuid);
    return {
      for (final row in rows)
        row['metric_id'] as int: MetricTarget.fromMap(row),
    };
  }

  Future<List<MetricValue>> getTrackedMetricValuesFor(
    String patientUuid,
    int metricId,
  ) async {
    dynamic rawValues = await DatabaseManager().getPatientMetricValuesForMetric(
      patientUuid,
      metricId,
    );
    List<MetricValue> metricValues = [];
    for (dynamic val in rawValues) {
      MetricValue mv = MetricValue.fromMap(val);
      metricValues.add(mv);
    }
    return metricValues;
  }

  // getTrackedMetricValuesFor above already existed and worked — it just had no caller.
  // Every `Metric.history` stayed permanently empty (its only mutators are `add`/`update`,
  // never invoked anywhere), so the scatter chart and any other consumer of a metric's
  // full reading history always saw zero points regardless of what was actually in
  // `patient_metric`. This is the one thing that actually populates it, from real rows.
  Future<void> loadHistoryFor(String patientUuid) async {
    for (final metric in tracked.values) {
      final values = await getTrackedMetricValuesFor(patientUuid, metric.id);
      metric.history = {for (final v in values) v.id: v};
    }
  }

  static void trackMetric({
    required int metricId,
    required String patientUuid,
  }) async {
    DatabaseManager().insertTrackingMetric(
      metricId: metricId,
      patientUuid: patientUuid,
    );
  }

  static void stopTrackingMetric({
    required int metricId,
    required String patientUuid,
  }) async {
    DatabaseManager().deleteTrackingMetric(
      metricId: metricId,
      patientUuid: patientUuid,
    );
  }

  static void setOnDashboard({
    required int metricId,
    required String patientUuid,
    required bool onDashboard,
  }) async {
    DatabaseManager().setMetricOnDashboard(
      metricId: metricId,
      patientUuid: patientUuid,
      onDashboard: onDashboard,
    );
  }

  static void setSource({
    required int metricId,
    required String patientUuid,
    required MetricSourceType source,
    String? sourceDetail,
  }) async {
    DatabaseManager().setMetricSource(
      metricId: metricId,
      patientUuid: patientUuid,
      source: source.name,
      sourceDetail: sourceDetail,
    );
    // Only a device has real identity worth remembering across visits (a reusable
    // "Omron BP710", not a one-off observation phrase) — this is what makes the
    // picker's "Your devices" list grow from the patient's own actual history.
    if (source == MetricSourceType.device &&
        sourceDetail != null &&
        sourceDetail.isNotEmpty) {
      DatabaseManager().recordDeviceUsage(
        patientUuid: patientUuid,
        name: sourceDetail,
        metricId: metricId,
      );
    }
  }
}

class MedicalMath {
  static double calculateBMI({
    required double? weight,
    required String weightUom,
    required double? height,
    required String heightUom,
  }) {
    if (weight == null || height == null) return 0.0;
    if (weight <= 0 || height <= 0) return 0.0;

    double weightInKg = weight;
    double heightInMeters = height;

    // Convert weight to kg if logged in lbs
    if (weightUom.toLowerCase() == 'lbs') {
      weightInKg = weight * 0.45359237;
    }

    // Convert height to meters based on input type
    final String cleanHeightUom = heightUom.toLowerCase();
    if (cleanHeightUom == 'cm') {
      heightInMeters = height / 100.0;
    } else if (cleanHeightUom == 'in' || cleanHeightUom == 'inches') {
      heightInMeters = (height * 2.54) / 100.0;
    }

    final double bmi = weightInKg / (heightInMeters * heightInMeters);

    // Round to one decimal place (standard medical presentation)
    return double.parse(bmi.toStringAsFixed(1));
  }
}

// 2. Create a global or static registry of named functions
class ConversionRegistry {
  static final Map<String, UnitConverter> registry = {
    'mmHg_to_kPa': (val) => val * 0.133322,
    'kPa_to_mmHg': (val) => val / 0.133322,
    'lbs_to_kg': (val) => val * 0.45359237,
    'kg_to_lbs': (val) => val / 0.45359237,
    'fahrenheit_to_celsius': (val) => (val - 32) * 5 / 9,
    'celsius_to_fahrenheit': (val) => (val * 9 / 5) + 32,
  };

  static UnitConverter? get(String name) => registry[name];
}

class MetricIcon {
  final IconData iconData;
  final Color color;
  MetricIcon({required this.iconData, required this.color});
}

Map<String, MetricIcon> metricIcons = {
  "Blood Pressure - Systolic": MetricIcon(
    iconData: Symbols.blood_pressure,
    color: Colors.red,
  ),
  "Blood Pressure - Diastolic": MetricIcon(
    iconData: Symbols.blood_pressure,
    color: Colors.red,
  ),
  "Heart Rate": MetricIcon(iconData: Symbols.ecg_heart, color: Colors.red),
  "Resting Heart Rate": MetricIcon(
    iconData: Symbols.hr_resting,
    color: Colors.red,
  ),
  "Body Temperature": MetricIcon(
    iconData: Symbols.body_system,
    color: Colors.red,
  ),
  "Body Weight": MetricIcon(iconData: Symbols.weight, color: Colors.red),
  "Body Mass Index (BMI)": MetricIcon(
    iconData: Symbols.body_fat,
    color: Colors.red,
  ),
  "Body Fat Percentage": MetricIcon(
    iconData: Symbols.body_fat,
    color: Colors.red,
  ),
  "Waist Circumference": MetricIcon(
    iconData: Symbols.measuring_tape,
    color: Colors.red,
  ),
  "Blood Oxygen Saturation (SpO2)": MetricIcon(
    iconData: Symbols.oxygen_saturation,
    color: Colors.red,
  ),
  "Apnea-Hypopnea Index (AHI)": MetricIcon(
    iconData: Symbols.sleep_score,
    color: Colors.red,
  ),
  "Peak Expiratory Flow Rate (PEFR)": MetricIcon(
    iconData: Symbols.air,
    color: Colors.red,
  ),
  "Forced Expiratory Volume in 1 Second (FEV1)": MetricIcon(
    iconData: Symbols.pulmonology,
    color: Colors.red,
  ),
  "Respiration Rate": MetricIcon(
    iconData: Symbols.respiratory_rate,
    color: Colors.red,
  ),
  "CPAP Usage Duration": MetricIcon(
    iconData: Symbols.air_purifier,
    color: Colors.red,
  ),
  "CPAP Mask Leak Rate": MetricIcon(
    iconData: Symbols.leak_add,
    color: Colors.red,
  ),
  "Estimated Average Glucose (eAG)": MetricIcon(
    iconData: Symbols.glucose,
    color: Colors.red,
  ),
  "Blood Glucose (Fasting / General)": MetricIcon(
    iconData: Symbols.glucose,
    color: Colors.red,
  ),
  "Blood Glucose (Postprandial / Post-Meal)": MetricIcon(
    iconData: Symbols.glucose,
    color: Colors.red,
  ),
  "Glycated Hemoglobin (HbA1c)": MetricIcon(
    iconData: Symbols.hematology,
    color: Colors.red,
  ),
  "Blood Ketones": MetricIcon(iconData: Symbols.hematology, color: Colors.red),
  "Urine Ketones": MetricIcon(iconData: Symbols.urology, color: Colors.red),
  "Insulin Dose Logged": MetricIcon(
    iconData: Symbols.glucose,
    color: Colors.red,
  ),
  "Carbohydrate Intake": MetricIcon(
    iconData: Symbols.cookie,
    color: Colors.red,
  ),
  "Total Cholesterol": MetricIcon(
    iconData: Symbols.lab_panel,
    color: Colors.red,
  ),
  "Low-Density Lipoprotein (LDL)": MetricIcon(
    iconData: Symbols.body_fat,
    color: Colors.red,
  ),
  "High-Density Lipoprotein (HDL)": MetricIcon(
    iconData: Symbols.body_fat,
    color: Colors.red,
  ),
  "Triglycerides": MetricIcon(iconData: Symbols.body_fat, color: Colors.red),
  "Prothrombin Time / INR": MetricIcon(
    iconData: Symbols.diagnosis,
    color: Colors.red,
  ),
  "Heart Rate Variability (HRV)": MetricIcon(
    iconData: Symbols.cardio_load,
    color: Colors.red,
  ),
  "Joint Pain Severity Score": MetricIcon(
    iconData: Symbols.rheumatology,
    color: Colors.red,
  ),
  "Morning Joint Stiffness Duration": MetricIcon(
    iconData: Symbols.rheumatology,
    color: Colors.red,
  ),
  "C-Reactive Protein (CRP)": MetricIcon(
    iconData: Symbols.experiment,
    color: Colors.red,
  ),
  "Erythrocyte Sedimentation Rate (ESR)": MetricIcon(
    iconData: Symbols.experiment,
    color: Colors.red,
  ),
  "Grip Strength": MetricIcon(iconData: Symbols.pan_tool, color: Colors.red),
  "General Pain Level": MetricIcon(
    iconData: Symbols.symptoms,
    color: Colors.red,
  ),
  "Serum Creatinine": MetricIcon(
    iconData: Symbols.hematology,
    color: Colors.red,
  ),
  "Estimated Glomerular Filtration Rate (eGFR)": MetricIcon(
    iconData: Symbols.experiment,
    color: Colors.red,
  ),
  "Blood Urea Nitrogen (BUN)": MetricIcon(
    iconData: Symbols.lab_panel,
    color: Colors.red,
  ),
  "Urine Output Volume": MetricIcon(
    iconData: Symbols.water_drop,
    color: Colors.red,
  ),
  "Water / Fluid Intake": MetricIcon(
    iconData: Symbols.water_bottle,
    color: Colors.red,
  ),
  "Daily Caloric Intake": MetricIcon(
    iconData: Symbols.fastfood,
    color: Colors.red,
  ),
  "Abdominal Pain Severity": MetricIcon(
    iconData: Symbols.symptoms,
    color: Colors.red,
  ),
  "Stool Consistency (Bristol Scale)": MetricIcon(
    iconData: Symbols.total_dissolved_solids,
    color: Colors.red,
  ),
  "Sleep Duration": MetricIcon(iconData: Symbols.snooze, color: Colors.red),
  "Sleep Quality Score": MetricIcon(
    iconData: Symbols.sleep_score,
    color: Colors.red,
  ),
  "Headache / Migraine Severity": MetricIcon(
    iconData: Symbols.cognition,
    color: Colors.red,
  ),
  "Daily Mood Score": MetricIcon(
    iconData: Symbols.add_reaction,
    color: Colors.red,
  ),
  "Stress Level": MetricIcon(
    iconData: Symbols.sentiment_stressed,
    color: Colors.red,
  ),
  "Cognitive Alertness": MetricIcon(
    iconData: Symbols.cognition_2,
    color: Colors.red,
  ),
};
