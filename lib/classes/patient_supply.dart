import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/widgets.dart' show IconData;

import 'package:carbon_ui/interfaces/listable.dart';

// Deliberately consumables only — needles, swabs, test strips, catheters — not durable
// equipment (wheelchairs, canes, glasses, BP monitors). A patient buys and keeps
// durable equipment once; it never runs out and never needs a reorder reminder, so it
// doesn't fit this "running low" model at all. Every category maps to a real, verified
// Material Symbols icon (checked against the installed material_symbols_icons package
// source, not guessed).
IconData iconForSupplyCategory(String? category) {
  switch (category) {
    case 'Injection Supplies':
      return Symbols.syringe;
    case 'Testing & Monitoring':
      return Symbols.glucose;
    case 'Wound Care':
      return Symbols.healing;
    case 'Continence & Ostomy':
      return Symbols.wc;
    case 'Respiratory':
      return Symbols.air;
    case 'Custom':
    default:
      return Symbols.inventory_2;
  }
}

// One entry from the seeded reference catalog (supply) — common consumables, some
// linked to specific conditions via condition_supply so they can be suggested once a
// patient logs that condition. Not exhaustive; a starting list, not a formulary.
class SupplyCatalogEntry implements Listable {
  final int id;
  final String name;
  final String? category;
  @override
  final String description;

  const SupplyCatalogEntry({required this.id, required this.name, this.category, this.description = ''});

  @override
  String get label => name;

  IconData get icon => iconForSupplyCategory(category);

  factory SupplyCatalogEntry.fromRow(Map<String, dynamic> row) {
    return SupplyCatalogEntry(
      id: row['id'] as int,
      name: row['name'] as String,
      category: row['category'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is SupplyCatalogEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// A supply the patient is actually tracking. Deliberately no FK back to the supply
// catalog — matching how PatientTest stores its own name/category rather than joining
// back to a reference table (see medical_test.dart): the catalog is a starting point,
// not a permanent link, and a custom (not-in-catalog) supply never had a catalog row to
// link to in the first place.
//
// quantityOnHand/reorderThreshold drive the reminder: due the moment quantity drops to
// or below the threshold, not on any predicted schedule — see SupplyReminder in
// remindable.dart for why a forecasted "runs out on" date was deliberately not built.
//
// linkedMedicationId is the one case where quantity tracks itself: when set, logging
// that medication's dose as taken decrements this supply by one automatically (see
// DatabaseManager.logMedicationDose) — real observed usage, not a guessed daily rate.
class PatientSupply {
  final int? id; // null until saved once
  final String name;
  final String? category;
  int quantityOnHand;
  int reorderThreshold;
  String? linkedMedicationId;

  PatientSupply({
    this.id,
    required this.name,
    this.category,
    this.quantityOnHand = 0,
    this.reorderThreshold = 5,
    this.linkedMedicationId,
  });

  IconData get icon => iconForSupplyCategory(category);
  bool get isLow => quantityOnHand <= reorderThreshold;

  factory PatientSupply.fromRow(Map<String, dynamic> row) {
    return PatientSupply(
      id: row['id'] as int?,
      name: row['name'] as String,
      category: row['category'] as String?,
      quantityOnHand: row['quantity_on_hand'] as int? ?? 0,
      reorderThreshold: row['reorder_threshold'] as int? ?? 5,
      linkedMedicationId: row['linked_medication_id'] as String?,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'name': name,
      'category': category,
      'quantity_on_hand': quantityOnHand,
      'reorder_threshold': reorderThreshold,
      'linked_medication_id': linkedMedicationId,
    };
  }
}
