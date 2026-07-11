import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'database_manager.dart';

enum MedicationShapes {
  almond,
  arrowHead,
  capsule,
  crescent,
  diamond,
  heart,
  hexagon,
  lozenge,
  oval,
  pentagon,
  rectangle,
  round,
  square,
  triangle,
}

extension MedicationShapesNames on MedicationShapes {
  String get name {
    switch (this) {
      case MedicationShapes.almond:
        return "Almond";
      case MedicationShapes.arrowHead:
        return "Arrow Head";
      case MedicationShapes.capsule:
        return "Capsule";
      case MedicationShapes.crescent:
        return "Crescent";
      case MedicationShapes.diamond:
        return "Diamond";
      case MedicationShapes.heart:
        return "Heart";
      case MedicationShapes.hexagon:
        return "Hexagon";
      case MedicationShapes.lozenge:
        return "Lozenge";
      case MedicationShapes.oval:
        return "Oval";
      case MedicationShapes.pentagon:
        return "Pentagon";
      case MedicationShapes.rectangle:
        return "Rectangle";
      case MedicationShapes.round:
        return "Round";
      case MedicationShapes.square:
        return "Square";
      case MedicationShapes.triangle:
        return "Triangle";
    }
  }
}

extension MedicationShapesSvg on MedicationShapes {
  String get svg {
    switch (this) {
      case MedicationShapes.almond:
        return "almond.svg";
      case MedicationShapes.arrowHead:
        return "arrow_head.svg";
      case MedicationShapes.capsule:
        return "capsule.svg";
      case MedicationShapes.crescent:
        return "crescent.svg";
      case MedicationShapes.diamond:
        return "diamond.svg";
      case MedicationShapes.heart:
        return "heart.svg";
      case MedicationShapes.hexagon:
        return "hexagon.svg";
      case MedicationShapes.lozenge:
        return "lozenge.svg";
      case MedicationShapes.oval:
        return "oval.svg";
      case MedicationShapes.pentagon:
        return "pentagon.svg";
      case MedicationShapes.rectangle:
        return "rectangle.svg";
      case MedicationShapes.round:
        return "round.svg";
      case MedicationShapes.square:
        return "square.svg";
      case MedicationShapes.triangle:
        return "triangle.svg";
    }
  }
}

//Oral Medications (Taken by mouth)
// Tablets: Compressed powders that can be traditional, chewable, or caplets (tablet shaped like a capsule).
// Some are designed to dissolve slowly in the mouth (sublingual or buccal) or in water (effervescent).
// Capsules: Medication enclosed in an outer gelatin shell. They can be hard shells, softgels, or sprinkle capsules filled with granules.
// Liquids & Syrups: Suspensions, solutions, drops, or elixirs that are swallowed.
// Topical Medications (Applied to the skin/mucous membranes)Creams,
// Ointments, & Gels: Semi-solid formulas applied directly to the skin for local relief.
// Transdermal Patches: Adhesive patches applied to the skin that release medication steadily into the bloodstream.
// Drops & Sprays: Liquid medications designed for the eyes, ears, or nasal passages.Inhalants (Breathed into the lungs)
// Metered-Dose Inhalers (MDIs): Devices that deliver a specific, aerosolized mist of medication.Dry Powder Inhalers (DPIs): Deliver medication as a fine dry powder.
// Nebulizers: Machines that turn liquid medication into a breathable mist.
// Injections (Parenterals)Intravenous (IV): Injected directly into the vein for immediate effect.
// Intramuscular (IM):Injected into a muscle.Subcutaneous: Injected into the fatty tissue just under the skin.
// Suppositories and InsertsMedication formulated into a solid base that melts at body temperature, designed to be inserted into the rectum or vagina to treat local conditions or for systemic absorption.
enum MedicationTypes {
  tablet,
  capsule,
  liquid,
  topical,
  ointment,
  gel,
  transdermalPatch,
  drops,
  spray,
  inhaler,
  suppository,
  injection,
  iv,
  nebulizer,
  unknown,
}

extension MedicationTypeNames on MedicationTypes {
  String get name {
    switch (this) {
      case MedicationTypes.tablet:
        return "Tablet";
      case MedicationTypes.capsule:
        return "Capsule";
      case MedicationTypes.liquid:
        return "Liquid";
      case MedicationTypes.topical:
        return "Topical";
      case MedicationTypes.ointment:
        return "Ointment";
      case MedicationTypes.gel:
        return "Gel";
      case MedicationTypes.transdermalPatch:
        return "Transdermal Patch";
      case MedicationTypes.drops:
        return "Drops";
      case MedicationTypes.spray:
        return "Spray";
      case MedicationTypes.inhaler:
        return "Inhaler";
      case MedicationTypes.suppository:
        return "suppository";
      case MedicationTypes.injection:
        return "Injection";
      case MedicationTypes.iv:
        return "Intravenous";
      case MedicationTypes.nebulizer:
        return "Nebulizer";
      case MedicationTypes.unknown:
        return "unknown";
    }
  }
}

enum MedicationSafetyAudit { auditNotPerformed, interactionsNotDetected, interactionsDetected }

class Frequency {
  final double? occurrences;
  final DateTime? specificTime;
  final String? latinRecurrence;
  final String? periodUoM;
  final int? period;
  final DateTime? start;
  final DateTime? end;
  final bool alert;

  Frequency({
    this.specificTime,
    this.latinRecurrence,
    this.periodUoM,
    this.period,
    this.start,
    this.end,
    required this.alert,
    this.occurrences,
  });
}

// InteractionConflict
class InteractionConflict {
  final String primaryMedName;
  final String conflictingMedName;
  final String interaction;

  InteractionConflict({required this.primaryMedName, required this.conflictingMedName, required this.interaction});

  // Returns a clean string for the Chip UI
  String get conflictDetail => "$conflictingMedName ($interaction)";

  // Basic string getters
  String get primary => primaryMedName;
  String get conflicting => conflictingMedName;
  String get type => interaction;

  // A helper getter for a formatted summary string
  String get description => "$primaryMedName interacts with $conflictingMedName";
  // Boilerplate for equality checks (important for List comparison)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionConflict &&
          runtimeType == other.runtimeType &&
          primaryMedName == other.primaryMedName &&
          conflictingMedName == other.conflictingMedName &&
          interaction == other.interaction;

  bool hasInteraction(String medicationName) =>
      ((primaryMedName == medicationName) && (primaryMedName != conflictingMedName));
  @override
  int get hashCode => primaryMedName.hashCode ^ conflictingMedName.hashCode ^ interaction.hashCode;

  // Handy for debugging in the console
  @override
  String toString() => 'Conflict: $primaryMedName <-> $conflictingMedName on $interaction';
}

class Medication {
  final String setId;
  final String genericName;
  final String? imageUrl;
  final String brandName;
  final bool hasLocalDataSheet;
  final Map<String, String> datasheetSections;
  final bool hasInteractionAlert;

  Medication({
    required this.setId,
    required this.genericName,
    required this.brandName,
    required this.hasLocalDataSheet,
    required this.datasheetSections,
    this.imageUrl,
    this.hasInteractionAlert = false,
  });

  factory Medication.fromFdaJson(Map<String, dynamic> json, {String classString = "", bool alert = false}) {
    final openFda = json['openfda'] ?? {};

    String getSection(String key) {
      List<dynamic>? section = json[key];
      return (section != null && section.isNotEmpty) ? section.join('\n\n') : "";
    }

    return Medication(
      setId: json['set_id'] ?? '',
      genericName: (openFda['generic_name'] as List?)?.first ?? 'Unknown Medication',
      brandName: (openFda['brand_name'] as List?)?.first ?? '',
      imageUrl: json['image_uri'],
      hasLocalDataSheet: json['has_local_dataset'] == 1,
      hasInteractionAlert: alert,
      datasheetSections: {
        'Boxed Warning': getSection('boxed_warning'),
        'Indications': getSection('indications_and_usage'),
        'Contraindications': getSection('contraindications'),
        'Dosage': getSection('dosage_and_administration'),
        'Interactions': getSection('drug_interactions'),
        'Precautions': getSection('warnings_and_cautions'),
        'Side Effects': getSection('adverse_reactions'),
      }..removeWhere((key, value) => value.isEmpty),
    );
  }

  String get interactionsText {
    return (datasheetSections['Interactions'] ?? "").toLowerCase();
  }

  // Helper for your bilateral scan logic
  bool containsClass(String className) {
    return interactionsText.contains(className.toLowerCase());
  }
}

class MedicationService {
  // Helper to pull the ID out of the messy FDA structure
  static String? _extractRxcui(Map<String, dynamic> fdaMap) {
    try {
      final openFda = fdaMap['openfda'] ?? {};
      final List? rxcuiList = openFda['rxcui'] as List?;
      return rxcuiList?.first?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDrugDataSheet(String medicationId, String name, String setId) async {
    final db = DatabaseManager();

    // --- 1. THE SYNC CHECK ---
    // Check if we already have the datasheet row in the local DB.
    Map<String, dynamic>? localData = setId.isNotEmpty ? await db.getStoredDatasheet(setId) : null;

    if (localData == null) {
      debugPrint('Local record missing for $name. Syncing from FDA...');

      // Inline FDA Search Logic
      String query = RegExp(r'^\d+$').hasMatch(name)
          ? 'openfda.rxcui:"$name"'
          : '(openfda.generic_name:"$name"+openfda.brand_name:"$name")';

      final url = Uri.parse('https://api.fda.gov/drug/label.json?search=$query&limit=1');

      try {
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final Map<String, dynamic> result = data['results'][0];

          // Resolve IDs
          final String newSetId = result['set_id'] ?? result['id'] ?? "";

          // Resolve Classes (Pharmacologic Classes)
          final String? rxcui = _extractRxcui(result);
          String classTags = "";
          if (rxcui != null && rxcui.isNotEmpty) {
            classTags = await fetchClassesByRxcui(rxcui);
          }
          if (classTags.isEmpty) {
            classTags = await fetchClassesFromRxNav(name);
          }

          // --- 2. THE PERSISTENCE ---
          // Save the datasheet blob and the classes string to the datasheet table
          await db.saveDatasheet(result, classTags);

          // Update the medication table to link the setId and flip has_local_datasheet to 1
          await db.updateMedicationSetId(medicationId, newSetId);

          // Update localData by pulling the newly saved row
          localData = await db.getStoredDatasheet(newSetId);
        } else {
          debugPrint("FDA API returned ${response.statusCode}");
          return null;
        }
      } catch (e) {
        debugPrint("Network failure during sync: $e");
        return null;
      }
    }

    // We return the raw database map.
    // The widget will handle the jsonDecode of the blob and the split() of the classes string.
    return localData;
  }

  static Future<List<String>> getPotentialMatches(String partialName) async {
    if (partialName.isEmpty) return [];

    final url = Uri.parse("https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term=$partialName&maxEntries=5");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List? candidates = data['approximateGroup']?['candidate'];

        if (candidates != null) {
          return candidates
              .map((c) => c['name']?.toString()) // Use null-safe access
              .where((name) => name != null && name.isNotEmpty) // Filter out nulls/empties
              .cast<String>() // Cast to a non-nullable String list
              .toSet() // Remove duplicates
              .toList();
        }
      }
    } catch (e) {
      debugPrint("RxNav Suggestion Error: $e");
    }
    return [];
  }

  static Future<String> fetchClassesFromRxNav(String medicationName) async {
    final url = Uri.parse("https://rxnav.nlm.nih.gov/REST/rxclass/class/byDrugName.json?drugName=$medicationName");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List infoList = data['rxclassDrugInfoList']?['rxclassDrugInfo'] ?? [];
        return infoList
            .where((item) => (item['rxclassMinConceptItem']?['classType'] ?? "").contains("EPC"))
            .map(
              (item) => (item['rxclassMinConceptItem']?['className']?.toString() ?? "")
                  .replaceAll(RegExp(r'\[.*?\]'), '')
                  .trim(),
            )
            .where((name) => name.isNotEmpty)
            .toSet()
            .join(', ');
      }
    } catch (e) {
      debugPrint("RxNav Parse Error: $e");
    }
    return "";
  }

  static Future<String> fetchClassesByRxcui(String rxcui) async {
    if (rxcui.isEmpty) return "";
    final url = Uri.parse("https://rxnav.nlm.nih.gov/REST/rxclass/class/byRxcui.json?rxcui=$rxcui");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List infoList = data['rxclassDrugInfoList']?['rxclassDrugInfo'] ?? [];
        return infoList
            .where((item) => item['rxclassMinConceptItem']?['classType'] == "EPC")
            .map(
              (item) => (item['rxclassMinConceptItem']?['className']?.toString() ?? "")
                  .replaceAll(RegExp(r'\[.*?\]'), '')
                  .trim(),
            )
            .where((name) => name.isNotEmpty && name.toLowerCase() != "other")
            .toSet()
            .join(', ');
      }
    } catch (e) {
      debugPrint("RxNav API Error: $e");
    }
    return "";
  }
}
