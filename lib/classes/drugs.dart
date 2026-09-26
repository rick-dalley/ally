import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

enum DrugCategories { stimulants, opioids, depressants, hallucinogens, cannabinoids }

class ClinicalFeature {
  List<String>? vitalSigns;
  List<String>? neurological;
  List<String>? physical;

  ClinicalFeature({this.vitalSigns, this.neurological, this.physical});

  // json.decode hands back List<dynamic>, which won't assign to List<String>.
  static List<String>? _strings(dynamic raw) => raw == null ? null : List<String>.from(raw);

  factory ClinicalFeature.fromJson(Map<String, dynamic> items){
    return ClinicalFeature(
      vitalSigns: _strings(items['vital_signs']),
      neurological: _strings(items['neurological']),
      physical: _strings(items['physical']),
    );
  }
}

class NamedValue {
  final String name;
  final dynamic value;

  NamedValue({required this.name, required this.value});

  factory NamedValue.fromJson(Map<String, dynamic> item){
    return NamedValue(name: item['name'], value: item['value']);
  }
}

typedef NamedValues = List<NamedValue>;

class Drug {
  final String id;
  final String name;
  final DrugCategories category;
  String? appearance;
  List<String> streetNames;
  List<String>? methods;
  NamedValues? affects;
  NamedValues? management;
  List<ClinicalFeature>? features;

  Drug({
    required this.id,
    required this.name,
    required this.streetNames,
    required this.category,
    this.features,
    this.appearance,
    this.management,
    this.methods,
    this.affects
  });

  static NamedValues getNamedValuesFromJson(dynamic json) {
    NamedValues namedValues = [];
    for (dynamic item in (json as List<dynamic>?) ?? const []) {
      namedValues.add(NamedValue.fromJson(item));
    }
    return namedValues;
  }


  factory Drug.fromJson(Map<String, dynamic> item) {

    // Most entries in drugs.json carry only name/medical_name/category/street_names,
    // so every other field is optional here — one sparse entry used to throw and
    // leave the whole database empty.
    dynamic rawClinicalFeatures = item['potential_affects'];
    List<ClinicalFeature> clinicalFeatures = [];
    for (dynamic rawFeature in (rawClinicalFeatures as List<dynamic>?) ?? const []) {
      clinicalFeatures.add(ClinicalFeature.fromJson(rawFeature));
    }
    dynamic rawManagement = item['medical_management'];
    NamedValues medicalManagement = getNamedValuesFromJson(rawManagement);
    dynamic rawAffects = item['potential_affects'];
    NamedValues potentialAffects = getNamedValuesFromJson(rawAffects);

    return Drug(
        // No id in the JSON; the name is unique within it.
        id: item['id'] ?? item['name'],
        name: item['name'],
        streetNames: List<String>.from(item['street_names'] ?? const []),
        // Stored capitalised ("Stimulants"), the enum is lower-case.
        category: DrugCategories.values.byName((item['category'] as String).toLowerCase()),
        appearance: item['appearance'],
        features: clinicalFeatures,
        methods: item['methods'] == null ? null : List<String>.from(item['methods']),
        management: medicalManagement,
        affects: potentialAffects
    );
  }
}

class DrugFactory {
  final Map<String, Drug> drugsByName = {};
  final List<Drug> allDrugs = [];
  final List<String> drugNames = [];
  final Set<DrugCategories> drugCategories = {};

  // Singleton pattern is often useful for a Factory
  static final DrugFactory instance = DrugFactory._internal();
  DrugFactory._internal();

  Future<void> initialize() async {
    try {
      // 1. Load the JSON string from assets
      final String jsonString = await rootBundle.loadString('assets/drugs/drugs.json');

      // 2. Decode the string into a List/Map
      final List<dynamic> jsonList = json.decode(jsonString);

      // 3. Initialize your factory
      DrugFactory.instance.build(jsonList);

    } catch (e) {
      debugPrint("Error loading drug database: $e");
    }
  }
  /// Loads the entire dataset and builds indices
  void build(List<dynamic> jsonList) {
    allDrugs.clear();
    drugsByName.clear();
    drugNames.clear();
    drugCategories.clear();

    for (var item in jsonList) {
      final drug = Drug.fromJson(item);

      allDrugs.add(drug);
      drugsByName[drug.name] = drug;
      drugNames.add(drug.name);
      drugCategories.add(drug.category);
    }
  }

  /// Helper to get drugs by category
  List<Drug> getDrugsByCategory(DrugCategories category) {
    return allDrugs.where((d) => d.category == category).toList();
  }

  /// Get the list of unique categories as strings for a UI dropdown
  List<String> get categoryNames =>
      drugCategories.map((e) => e.name.toUpperCase()).toList();
}