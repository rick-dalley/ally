import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:uuid/uuid.dart';

import 'listable.dart';

enum JourneySupports implements Listable {
  device,
  medication,
  activity,
  specialist;

  @override
  String get description {
    switch (this) {
      case JourneySupports.device:
        return "Connected BLE Device";
      case JourneySupports.medication:
        return "Associated Medication";
      case JourneySupports.activity:
        return "Physical Activity Routine";
      case JourneySupports.specialist:
        return "Assigned Care Specialist";
    }
  }

  @override
  String get label {
    switch (this) {
      case JourneySupports.device:
        return "device";
      case JourneySupports.medication:
        return "medication";
      case JourneySupports.activity:
        return "activity";
      case JourneySupports.specialist:
        return "specialist";
    }
  }
}

// Create a reusable instance
const uuid = Uuid();
typedef UUID = String; // Generate a v4 (random) string UUID

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

  UnitOfMeasure({required this.symbol, required this.name, required this.converters});

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

    return UnitOfMeasure(symbol: rawSymbol, name: rawName, converters: conversionFunctions);
  }

  // Convert this unit to another target unit
  double convertTo(String targetSymbol, double value) {
    final conversionFunction = converters[targetSymbol];
    if (conversionFunction == null) {
      throw UnsupportedError('No conversion path from $symbol to $targetSymbol');
    }
    return conversionFunction(value);
  }
}

class Metric {
  final int id;
  final String name;
  final String category;
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

    Metric metric = Metric(
      id: items['id'] ?? 0,
      name: items['name'] ?? '',
      category: category,
      searchTerms: searchTerms,
      safeLowerValue: (items['safe_lower'] as num?)?.toDouble(),
      safeUpperValue: (items['safe_upper'] as num?)?.toDouble(),
      healthyLowerValue: (items['healthy_lower'] as num?)?.toDouble(),
      healthyUpperValue: (items['healthy_upper'] as num?)?.toDouble(),
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
  MetricValue({required this.value, required this.recorded, required this.uom, required this.metric});

  /// Factory constructor to parse database raw maps cleanly
  factory MetricValue.fromMap(Map<String, dynamic> item) {
    // Safely parse the dynamic value column to a double
    final dynamic rawValue = item['metric_value'] ?? item['value'];
    final double parsedValue = (rawValue as num?)?.toDouble() ?? 0.0;
    final String? rawUom = item['uom'];
    final String uomValue = rawUom ?? "";

    // Safely handle the string-to-date conversion parsing
    final dynamic rawDate = item['recorded_at'] ?? item['recorded'];
    final DateTime parsedDate = rawDate != null
        ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
        : DateTime.now();

    final int metricId = item['metric'] ?? 0;
    return MetricValue(value: parsedValue, recorded: parsedDate, uom: uomValue, metric: metricId);
  }

  /// Converts the model object back into a map structured for SQLite writes
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metric': metric,
      'metric_value': value,
      'recorded_at': recorded.toIso8601String(), // Safe string format for database entries
      'uom': uom,
    };
  }
}

class Metrics {
  Map<int, Metric> tracked = {};
  Map<int, Metric> untracked = {};
  Map<int, Metric> all = {};

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
      Metric metric = Metric.fromMap(rawMetric, "");
      all[metric.id] = metric;
    }
  }

  Future<void> buildMapsFor(String patientUuid) async {
    final rawTracked = await DatabaseManager().getTrackedMetrics(patientUuid);
    tracked.clear();
    untracked.clear();

    for (Map<String, dynamic> rawMetric in rawTracked) {
      int metricId = rawMetric['metric_id'] ?? rawMetric['id'];
      Metric? metric = all[metricId];
      if (metric != null) {
        tracked[metric.id] = metric;
      }
    }

    all.forEach((k, v) {
      if (!tracked.containsKey(k)) {
        untracked[k] = v;
      }
    });
  }

  Future<Map<int, Metric>> getTrackedMetricsFor(String patientUuid, bool refresh) async {
    if (refresh) {
      await buildMapsFor(patientUuid);
    }
    return tracked;
  }

  Future<Map<int, Metric>> getUntrackedMetricsFor(String patientUuid, bool refresh) async {
    if (refresh) {
      await buildMapsFor(patientUuid);
    }
    return untracked;
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
  "Blood Pressure - Systolic": MetricIcon(iconData: Symbols.blood_pressure, color: Colors.red),
  "Blood Pressure - Diastolic": MetricIcon(iconData: Symbols.blood_pressure, color: Colors.red),
  "Heart Rate": MetricIcon(iconData: Symbols.ecg_heart, color: Colors.red),
  "Resting Heart Rate": MetricIcon(iconData: Symbols.hr_resting, color: Colors.red),
  "Body Temperature": MetricIcon(iconData: Symbols.body_system, color: Colors.red),
  "Body Weight": MetricIcon(iconData: Symbols.weight, color: Colors.red),
  "Body Mass Index (BMI)": MetricIcon(iconData: Symbols.body_fat, color: Colors.red),
  "Body Fat Percentage": MetricIcon(iconData: Symbols.body_fat, color: Colors.red),
  "Waist Circumference": MetricIcon(iconData: Symbols.measuring_tape, color: Colors.red),
  "Blood Oxygen Saturation (SpO2)": MetricIcon(iconData: Symbols.oxygen_saturation, color: Colors.red),
  "Apnea-Hypopnea Index (AHI)": MetricIcon(iconData: Symbols.sleep_score, color: Colors.red),
  "Peak Expiratory Flow Rate (PEFR)": MetricIcon(iconData: Symbols.air, color: Colors.red),
  "Forced Expiratory Volume in 1 Second (FEV1)": MetricIcon(iconData: Symbols.pulmonology, color: Colors.red),
  "Respiration Rate": MetricIcon(iconData: Symbols.respiratory_rate, color: Colors.red),
  "CPAP Usage Duration": MetricIcon(iconData: Symbols.air_purifier, color: Colors.red),
  "CPAP Mask Leak Rate": MetricIcon(iconData: Symbols.leak_add, color: Colors.red),
  "Estimated Average Glucose (eAG)": MetricIcon(iconData: Symbols.glucose, color: Colors.red),
  "Blood Glucose (Fasting / General)": MetricIcon(iconData: Symbols.glucose, color: Colors.red),
  "Blood Glucose (Postprandial / Post-Meal)": MetricIcon(iconData: Symbols.glucose, color: Colors.red),
  "Glycated Hemoglobin (HbA1c)": MetricIcon(iconData: Symbols.hematology, color: Colors.red),
  "Blood Ketones": MetricIcon(iconData: Symbols.hematology, color: Colors.red),
  "Urine Ketones": MetricIcon(iconData: Symbols.urology, color: Colors.red),
  "Insulin Dose Logged": MetricIcon(iconData: Symbols.glucose, color: Colors.red),
  "Carbohydrate Intake": MetricIcon(iconData: Symbols.cookie, color: Colors.red),
  "Total Cholesterol": MetricIcon(iconData: Symbols.lab_panel, color: Colors.red),
  "Low-Density Lipoprotein (LDL)": MetricIcon(iconData: Symbols.body_fat, color: Colors.red),
  "High-Density Lipoprotein (HDL)": MetricIcon(iconData: Symbols.body_fat, color: Colors.red),
  "Triglycerides": MetricIcon(iconData: Symbols.body_fat, color: Colors.red),
  "Prothrombin Time / INR": MetricIcon(iconData: Symbols.diagnosis, color: Colors.red),
  "Heart Rate Variability (HRV)": MetricIcon(iconData: Symbols.cardio_load, color: Colors.red),
  "Joint Pain Severity Score": MetricIcon(iconData: Symbols.rheumatology, color: Colors.red),
  "Morning Joint Stiffness Duration": MetricIcon(iconData: Symbols.rheumatology, color: Colors.red),
  "C-Reactive Protein (CRP)": MetricIcon(iconData: Symbols.experiment, color: Colors.red),
  "Erythrocyte Sedimentation Rate (ESR)": MetricIcon(iconData: Symbols.experiment, color: Colors.red),
  "Grip Strength": MetricIcon(iconData: Symbols.pan_tool, color: Colors.red),
  "General Pain Level": MetricIcon(iconData: Symbols.symptoms, color: Colors.red),
  "Serum Creatinine": MetricIcon(iconData: Symbols.hematology, color: Colors.red),
  "Estimated Glomerular Filtration Rate (eGFR)": MetricIcon(iconData: Symbols.experiment, color: Colors.red),
  "Blood Urea Nitrogen (BUN)": MetricIcon(iconData: Symbols.lab_panel, color: Colors.red),
  "Urine Output Volume": MetricIcon(iconData: Symbols.water_drop, color: Colors.red),
  "Water / Fluid Intake": MetricIcon(iconData: Symbols.water_bottle, color: Colors.red),
  "Daily Caloric Intake": MetricIcon(iconData: Symbols.fastfood, color: Colors.red),
  "Abdominal Pain Severity": MetricIcon(iconData: Symbols.symptoms, color: Colors.red),
  "Stool Consistency (Bristol Scale)": MetricIcon(iconData: Symbols.total_dissolved_solids, color: Colors.red),
  "Sleep Duration": MetricIcon(iconData: Symbols.snooze, color: Colors.red),
  "Sleep Quality Score": MetricIcon(iconData: Symbols.sleep_score, color: Colors.red),
  "Headache / Migraine Severity": MetricIcon(iconData: Symbols.cognition, color: Colors.red),
  "Daily Mood Score": MetricIcon(iconData: Symbols.add_reaction, color: Colors.red),
  "Stress Level": MetricIcon(iconData: Symbols.sentiment_stressed, color: Colors.red),
  "Cognitive Alertness": MetricIcon(iconData: Symbols.cognition_2, color: Colors.red),
};
