import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/widgets.dart' show IconData;

// Every category maps to a real, verified Material Symbols icon (checked against the
// installed material_symbols_icons package source, not guessed) — same discipline as
// iconForTestCategory/iconForSupplyCategory.
IconData iconForAllergenCategory(String? category) {
  switch (category) {
    case 'Environmental & Airborne Allergens':
      return Symbols.air;
    case 'Food Allergens':
      return Symbols.nutrition;
    case 'Medications & Drug Allergies':
      return Symbols.medication;
    case 'Insect Stings':
      return Symbols.pest_control;
    case 'Skin & Contact Allergens':
      return Symbols.dermatology;
    case 'Custom':
    default:
      return Symbols.allergy;
  }
}

class AllergenReference {
  final int id;
  final String name;
  final String category;

  const AllergenReference({required this.id, required this.name, required this.category});

  factory AllergenReference.fromMap(Map<String, dynamic> map) {
    return AllergenReference(id: map['id'] as int, name: map['name'] as String, category: map['category'] as String);
  }
}

// How badly the patient reacts — the whole reason this matters more than a plain
// checklist: a "severe" match against a new prescription deserves a much louder warning
// than a "mild" one, and the drug-allergy cross-check (see prescription_screen.dart)
// reads this directly to decide how urgently to flag a conflict.
enum AllergySeverity {
  mild,
  moderate,
  severe;

  String get label {
    switch (this) {
      case AllergySeverity.mild:
        return "Mild";
      case AllergySeverity.moderate:
        return "Moderate";
      case AllergySeverity.severe:
        return "Severe";
    }
  }
}

// A patient's recorded allergy — always tied to a real allergen_id (even a
// patient-typed one gets a catalog row first, via getOrCreateCustomAllergen), the same
// FK-based shape as PatientCondition rather than PatientTest/PatientSupply's
// denormalized shape, because this reuses the exact same chip-toggle-selection UI
// pattern as Existing Medical Conditions, which depends on matching by a stable id.
class PatientAllergy {
  final int? id;
  final String patientUuid;
  final int allergenId;
  String name; // populated from the catalog after load, not a stored column — see PatientCondition
  String category;
  AllergySeverity severity;
  String reaction;

  PatientAllergy({
    this.id,
    required this.patientUuid,
    required this.allergenId,
    this.name = "",
    this.category = "",
    this.severity = AllergySeverity.mild,
    this.reaction = "",
  });

  factory PatientAllergy.fromAllergen(String patientUuid, AllergenReference allergen) {
    return PatientAllergy(patientUuid: patientUuid, allergenId: allergen.id, name: allergen.name, category: allergen.category);
  }

  factory PatientAllergy.fromMap(Map<String, dynamic> map) {
    return PatientAllergy(
      id: map['id'] as int,
      patientUuid: map['patient_uuid'] as String,
      allergenId: map['allergen_id'] as int,
      severity: AllergySeverity.values[map['severity'] as int? ?? 0],
      reaction: map['reaction'] as String? ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_uuid': patientUuid,
      'allergen_id': allergenId,
      'severity': severity.index,
      'reaction': reaction,
    };
  }
}

// A medication whose name text-matches a recorded allergy. This is a plain
// case-insensitive name comparison, not real pharmacology — it can't know that
// "Amoxicillin" belongs to the penicillin class, only that a medication is literally
// named something like "Penicillin". That's the same fidelity the app's existing
// drug-drug interaction checker already operates at (exact-ish name matching against a
// CSV, not a real drug-class taxonomy), so this isn't a step down from what's already
// trusted elsewhere — but the UI built on top of this must say "possible match, confirm
// with your pharmacist," never present it as a confident clinical finding.
class AllergyConflict {
  final String medicationName;
  final String allergenName;
  final AllergySeverity severity;

  const AllergyConflict({required this.medicationName, required this.allergenName, required this.severity});

  bool matchesMedication(String name) => name == medicationName;
}

List<AllergyConflict> findAllergyConflicts(Iterable<String> medicationNames, List<Map<String, dynamic>> allergyRows) {
  final List<AllergyConflict> conflicts = [];
  for (final row in allergyRows) {
    final String allergenName = row['name'] as String;
    final String allergenLower = allergenName.toLowerCase();
    final AllergySeverity severity = AllergySeverity.values[row['severity'] as int? ?? 0];

    for (final medName in medicationNames) {
      if (medName.isEmpty) continue;
      final String medLower = medName.toLowerCase();
      if (medLower.contains(allergenLower) || allergenLower.contains(medLower)) {
        conflicts.add(AllergyConflict(medicationName: medName, allergenName: allergenName, severity: severity));
      }
    }
  }
  return conflicts;
}
