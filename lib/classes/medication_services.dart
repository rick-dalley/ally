import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/contactable.dart';
import 'package:triage/classes/phone.dart';
import 'package:triage/classes/uuid.dart';

import 'address.dart';
import 'database_manager.dart';

enum TabletShapes {
  almond,
  arrowHead,
  capsule,
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

extension TabletShapesNames on TabletShapes {
  String get name {
    switch (this) {
      case TabletShapes.almond:
        return "Almond";
      case TabletShapes.arrowHead:
        return "Arrow Head";
      case TabletShapes.capsule:
        return "Capsule";
      case TabletShapes.diamond:
        return "Diamond";
      case TabletShapes.heart:
        return "Heart";
      case TabletShapes.hexagon:
        return "Hexagon";
      case TabletShapes.lozenge:
        return "Lozenge";
      case TabletShapes.oval:
        return "Oval";
      case TabletShapes.pentagon:
        return "Pentagon";
      case TabletShapes.rectangle:
        return "Rectangle";
      case TabletShapes.round:
        return "Round";
      case TabletShapes.square:
        return "Square";
      case TabletShapes.triangle:
        return "Triangle";
    }
  }
}

extension TabletShapeSvg on TabletShapes {
  String get svg {
    switch (this) {
      case TabletShapes.almond:
        return "almond.svg";
      case TabletShapes.arrowHead:
        return "arrow_head.svg";
      case TabletShapes.capsule:
        return "capsule.svg";
      case TabletShapes.diamond:
        return "diamond.svg";
      case TabletShapes.heart:
        return "heart.svg";
      case TabletShapes.hexagon:
        return "hexagon.svg";
      case TabletShapes.lozenge:
        return "lozenge.svg";
      case TabletShapes.oval:
        return "oval.svg";
      case TabletShapes.pentagon:
        return "pentagon.svg";
      case TabletShapes.rectangle:
        return "rectangle.svg";
      case TabletShapes.round:
        return "round.svg";
      case TabletShapes.square:
        return "square.svg";
      case TabletShapes.triangle:
        return "triangle.svg";
    }
  }
}

enum TabletColors { white, pink, yellow, tan, cyan, orange, red, purple, green, peach, black }

extension TabletColorsColor on TabletColors {
  Color get color {
    switch (this) {
      case TabletColors.white:
        return const Color(0xFFF8F8FF);
      case TabletColors.pink:
        return const Color(0xFFFFC0CB);
      case TabletColors.yellow:
        return const Color(0xFFFFFF00);
      case TabletColors.tan:
        return const Color(0xFFD2B48C);
      case TabletColors.cyan:
        return const Color(0xFF00FFFF);
      case TabletColors.orange:
        return const Color(0xFFFFA500);
      case TabletColors.red:
        return const Color(0xFFFF0000);
      case TabletColors.purple:
        return const Color(0xFFBC8F8F);
      case TabletColors.green:
        return const Color(0xFF90EE90);
      case TabletColors.peach:
        return const Color(0xFFFFDAB9);
      case TabletColors.black:
        return const Color(0xFF000000);
    }
  }
}

extension TableColorsLabel on TabletColors {
  String get label {
    switch (this) {
      case TabletColors.white:
        return "White";
      case TabletColors.pink:
        return "Pink";
      case TabletColors.yellow:
        return "Yellow";
      case TabletColors.tan:
        return "Tan";
      case TabletColors.cyan:
        return "Turquoise";
      case TabletColors.orange:
        return "Orange";
      case TabletColors.red:
        return "Red";
      case TabletColors.purple:
        return "Purple";
      case TabletColors.green:
        return "Green";
      case TabletColors.peach:
        return "Peach";
      case TabletColors.black:
        return "Black";
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

// Named `label`/`description`/`icon` rather than `name` deliberately — Dart enums
// already have a built-in `.name` getter (the raw identifier, e.g. "tablet"), and an
// extension can't override it: `type.name` always resolves to the built-in one, no
// matter what an extension declares, so an extension named `name` here would be
// silently unreachable dead code (this file previously had exactly that bug).
extension MedicationTypeDetails on MedicationTypes {
  String get label {
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
        return "Suppository";
      case MedicationTypes.injection:
        return "Injection";
      case MedicationTypes.iv:
        return "Intravenous (IV)";
      case MedicationTypes.nebulizer:
        return "Nebulizer";
      case MedicationTypes.unknown:
        return "Something Else";
    }
  }

  String get description {
    switch (this) {
      case MedicationTypes.tablet:
        return "A solid pill you swallow whole, chew, or let dissolve";
      case MedicationTypes.capsule:
        return "Medicine sealed inside a soft or hard shell you swallow";
      case MedicationTypes.liquid:
        return "A syrup, solution, or drops you swallow";
      case MedicationTypes.topical:
        return "A cream or lotion you apply to your skin";
      case MedicationTypes.ointment:
        return "A thick, soothing layer you apply to your skin";
      case MedicationTypes.gel:
        return "A smooth gel you apply to your skin";
      case MedicationTypes.transdermalPatch:
        return "A sticky patch that releases medicine through your skin";
      case MedicationTypes.drops:
        return "Liquid drops for your eyes, ears, or nose";
      case MedicationTypes.spray:
        return "A fine mist you spray into your nose or mouth";
      case MedicationTypes.inhaler:
        return "A device you breathe in from to get a measured dose";
      case MedicationTypes.suppository:
        return "Inserted rectally or vaginally, dissolves at body temperature";
      case MedicationTypes.injection:
        return "Given by needle into a muscle or under the skin";
      case MedicationTypes.iv:
        return "Given directly into a vein, usually by a nurse or doctor";
      case MedicationTypes.nebulizer:
        return "A machine that turns liquid medicine into a mist you breathe";
      case MedicationTypes.unknown:
        return "Not sure yet — you can update this later";
    }
  }

  IconData get icon {
    switch (this) {
      case MedicationTypes.tablet:
        return Symbols.medication;
      case MedicationTypes.capsule:
        return Symbols.pill;
      case MedicationTypes.liquid:
        return Symbols.medication_liquid;
      case MedicationTypes.topical:
        return Symbols.spa;
      case MedicationTypes.ointment:
        return Symbols.healing;
      case MedicationTypes.gel:
        return Symbols.texture;
      case MedicationTypes.transdermalPatch:
        return Symbols.sanitizer;
      case MedicationTypes.drops:
        return Symbols.colorize;
      case MedicationTypes.spray:
        return Symbols.mist;
      case MedicationTypes.inhaler:
        return Symbols.air;
      case MedicationTypes.suppository:
        return Symbols.grain;
      case MedicationTypes.injection:
        return Symbols.syringe;
      case MedicationTypes.iv:
        return Symbols.bloodtype;
      case MedicationTypes.nebulizer:
        return Symbols.humidity_mid;
      case MedicationTypes.unknown:
        return Symbols.help;
    }
  }

  // Only pill-shaped forms have a meaningful shape/color to pick in the wizard.
  bool get isPillShaped => this == MedicationTypes.tablet || this == MedicationTypes.capsule;
}

enum MedicationSafetyAudit { auditNotPerformed, interactionsNotDetected, interactionsDetected }

class Frequency {
  final double? occurrences;
  final DateTime? specificTime;
  final String? latinRecurrence;
  final String? periodUoM;
  final int? period;
  final DateTime? start;
  final bool alert;

  Frequency({
    this.specificTime,
    this.latinRecurrence,
    this.periodUoM,
    this.period,
    this.start,
    required this.alert,
    this.occurrences,
  });
}

enum WizardSteps { name, type, dosage, frequency, reminders, shape, color }

extension WizardStepsName on WizardSteps {
  String get label {
    switch (this) {
      case WizardSteps.name:
        return "Medication Name";
      case WizardSteps.dosage:
        return "Dosage";
      case WizardSteps.type:
        return "Type";
      case WizardSteps.frequency:
        return "Frequency";
      case WizardSteps.reminders:
        return "Reminders";
      case WizardSteps.shape:
        return "Shape";
      case WizardSteps.color:
        return "Color";
    }
  }
}

enum DosageUnit { mg, mcg, mL, units, tablets }

extension DosageUnitLabel on DosageUnit {
  String get label {
    switch (this) {
      case DosageUnit.mg:
        return "mg";
      case DosageUnit.mcg:
        return "mcg";
      case DosageUnit.mL:
        return "mL";
      case DosageUnit.units:
        return "units (IU)";
      case DosageUnit.tablets:
        return "tablet(s)";
    }
  }
}

enum ReminderChannel { chime, text, email, wearable }

extension ReminderChannelDetails on ReminderChannel {
  String get label {
    switch (this) {
      case ReminderChannel.chime:
        return "Chime on my phone";
      case ReminderChannel.text:
        return "Text message";
      case ReminderChannel.email:
        return "Email";
      case ReminderChannel.wearable:
        return "Wearable device";
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderChannel.chime:
        return Symbols.notifications;
      case ReminderChannel.text:
        return Symbols.sms;
      case ReminderChannel.email:
        return Symbols.mail;
      case ReminderChannel.wearable:
        return Symbols.watch;
    }
  }
}

enum WearableAlertMode { audible, vibration, both }

extension WearableAlertModeLabel on WearableAlertMode {
  String get label {
    switch (this) {
      case WearableAlertMode.audible:
        return "Sound";
      case WearableAlertMode.vibration:
        return "Vibration";
      case WearableAlertMode.both:
        return "Sound and vibration";
    }
  }
}

// UI-layer bundle for the wizard's Reminders step — not a database row shape (see
// DatabaseManager.saveMedicationReminderPreference for how this gets persisted).
class ReminderPreference {
  final bool enabled;
  final Set<ReminderChannel> channels;
  final int leadMinutes;
  final WearableAlertMode? wearableMode;

  const ReminderPreference({this.enabled = false, this.channels = const {}, this.leadMinutes = 0, this.wearableMode});
}

// InteractionConflict
String normalizedInteractionPairKey(String a, String b) {
  final List<String> sorted = [a.toLowerCase().trim(), b.toLowerCase().trim()]..sort();
  return '${sorted[0]}|${sorted[1]}';
}

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

  // Order-independent key for this pair, so acknowledging from either medication's card
  // (A's card sees "A conflicts with B", B's card sees "B conflicts with A") records and
  // recognizes the same underlying acknowledgment.
  String get pairKey => normalizedInteractionPairKey(primaryMedName, conflictingMedName);
  @override
  int get hashCode => primaryMedName.hashCode ^ conflictingMedName.hashCode ^ interaction.hashCode;

  // Handy for debugging in the console
  @override
  String toString() => 'Conflict: $primaryMedName <-> $conflictingMedName on $interaction';
}

class Pharmacy implements Contactable {
  final Address address;
  const Pharmacy({required this.address});
  @override
  String get email => '';

  @override
  Phone get phone => Phone(number: '', isMain: false, phoneType: PhoneTypes.cell);
}

class Dosage {}

// Tolerates null / unrecognized values (e.g. topical medications with no shape,
// or rows seeded before these columns existed) rather than throwing.
TabletShapes? _parseTabletShape(dynamic raw) {
  if (raw == null) return null;
  try {
    return TabletShapes.values.byName(raw.toString());
  } catch (_) {
    return null;
  }
}

TabletColors? _parseTabletColor(dynamic raw) {
  if (raw == null) return null;
  try {
    return TabletColors.values.byName(raw.toString());
  } catch (_) {
    return null;
  }
}

class Medication {
  final String id;
  final String patientUuid;
  final String name;
  String? setId;
  String? severity;
  String? genericName;
  String? imageUrl;
  String? brandName;
  bool hasLocalDataSheet;
  Uint8List? imageBits;
  Map<String, String>? datasheetSections;
  bool hasInteractionAlert;
  bool hasInteractions;
  bool isSyncing;
  // The raw values actually stored in the `medication` table (e.g. "50 mg", "Quaque die").
  String? dose;
  String? freq;
  // Reserved for a future structured dosing schedule (see WizardSteps/Frequency) — not
  // populated from the database today; `freq` above is the real current value.
  Frequency? frequency;
  TabletShapes? shape;
  TabletColors? color;
  Medication({
    required this.id,
    required this.name,
    this.setId,
    this.severity,
    required this.patientUuid,
    required this.genericName,
    this.brandName,
    this.hasLocalDataSheet = false,
    this.datasheetSections,
    this.imageBits,
    this.imageUrl,
    this.dose,
    this.freq,
    this.frequency,
    this.hasInteractionAlert = false,
    this.hasInteractions = false,
    this.isSyncing = false,
    this.shape,
    this.color,
  });

  factory Medication.fromMap(Map<String, dynamic> map, String patient, {String classString = "", bool alert = false}) {
    final openFda = map['openfda'] ?? {};

    String getSection(String key) {
      List<dynamic>? section = map[key];
      return (section != null && section.isNotEmpty) ? section.join('\n\n') : "";
    }

    String? medicationId = map['id'];
    medicationId = medicationId ?? uuid.toString();
    String? rawPatientUuid = map['patient_uuid'];
    rawPatientUuid = rawPatientUuid ?? patient;
    String? rawSeverity = map["severity"] ?? "Neutral";
    return Medication(
      id: medicationId,
      patientUuid: rawPatientUuid,
      setId: map['set_id'] ?? '',
      name: map['name'],
      genericName: (openFda['generic_name'] as List?)?.first ?? 'Unknown Medication',
      brandName: (openFda['brand_name'] as List?)?.first ?? '',
      imageUrl: map['image_uri'],
      hasLocalDataSheet: map['has_local_dataset'] == 1,
      hasInteractionAlert: alert,
      severity: rawSeverity,
      dose: map['dose'],
      freq: map['freq'],
      shape: _parseTabletShape(map['shape']),
      color: _parseTabletColor(map['color']),
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
    String text = datasheetSections?['Interactions'] ?? "";
    return text.toLowerCase();
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

  static Future<List<Map<String, dynamic>>> getPrescriptionFor(String patientUuid) async {
    List<Map<String, dynamic>> prescription = await DatabaseManager().getMedicationsForPatient(patientUuid);
    return prescription;
  }

  static Future<Map<String, dynamic>?> getDrugDataSheet(String medicationId, String name, String setId) async {
    final db = DatabaseManager();

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
            classTags = await fetchClassesByRxCUI(rxcui);
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

  static Future<String> fetchClassesByRxCUI(String rxcui) async {
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
