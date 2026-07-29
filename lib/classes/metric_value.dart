import 'package:uuid/uuid.dart';

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
  List<UnitOfMeasure> unitsOfMeasure;
  final double? safeUpperValue;
  final double? safeLowerValue;
  final double? healthyUpperValue;
  final double? healthyLowerValue;
  Map<UUID, MetricValue> history;

  Metric({
    required this.id,
    required this.name,
    this.safeLowerValue,
    this.safeUpperValue,
    this.healthyLowerValue,
    this.healthyUpperValue,
  }) : history = {},
       unitsOfMeasure = [];

  factory Metric.fromMap(Map<String, dynamic> items) {
    List<UnitOfMeasure> uoms = [];
    dynamic rawUoMs = items['units_of_measure'];
    if (rawUoMs != null && rawUoMs is List) {
      for (dynamic rawUoM in rawUoMs) {
        if (rawUoM is Map<String, dynamic>) {
          UnitOfMeasure uom = UnitOfMeasure.fromMap(rawUoM);
          uoms.add(uom);
        }
      }
    }

    Metric metric = Metric(
      id: items['id'] ?? 0,
      name: items['name'] ?? '',
      safeLowerValue: (items['safe_lower'] as num?)?.toDouble(),
      safeUpperValue: (items['safe_upper'] as num?)?.toDouble(),
      healthyLowerValue: (items['healthy_lower'] as num?)?.toDouble(),
      healthyUpperValue: (items['healthy_upper'] as num?)?.toDouble(),
    );
    metric.unitsOfMeasure = uoms;
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
