import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/widgets.dart' show IconData;

import 'listable.dart';

// Deliberately clinic/lab tests only — at-home readings (blood pressure, glucose,
// SpO2, weight, etc.) mostly duplicate what the Metrics screen already tracks with a
// real value/trend system this catalog doesn't have; Richard confirmed narrowing scope
// to out-of-house tests only rather than re-solving what Metrics already solves.
// Every catalog category maps to a real, verified Material Symbols medical-specialty
// icon (checked against the installed material_symbols_icons package source, not
// guessed) rather than one generic icon for every test.
IconData iconForTestCategory(String? category) {
  switch (category) {
    case 'Cancer Screening':
      return Symbols.oncology;
    case 'Cardiovascular':
      return Symbols.cardiology;
    case 'General Bloodwork':
      return Symbols.bloodtype;
    case 'Imaging':
      return Symbols.radiology;
    case 'Infectious Disease':
      return Symbols.coronavirus;
    case "Men's Health":
      return Symbols.urology;
    case 'Metabolic':
      return Symbols.endocrinology;
    case 'Respiratory':
      return Symbols.pulmonology;
    case 'General':
    default:
      return Symbols.stethoscope;
  }
}

// One entry from the seeded reference catalog (test_catalog) — the ~34 common
// out-of-house tests a patient can choose to start tracking. Not exhaustive; a
// starting list, not a diagnostic-coding system.
class TestCatalogEntry implements Listable {
  final int id;
  final String name;
  final String? category;
  @override
  final String description;

  const TestCatalogEntry({required this.id, required this.name, this.category, this.description = ''});

  @override
  String get label => name;

  IconData get icon => iconForTestCategory(category);

  factory TestCatalogEntry.fromRow(Map<String, dynamic> row) {
    return TestCatalogEntry(
      id: row['id'] as int,
      name: row['name'] as String,
      category: row['category'] as String?,
      description: (row['description'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is TestCatalogEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// A test the patient is actually tracking — chosen from the catalog, with its own
// history/next-due state and any special instructions given by the lab (e.g. "no
// calcium supplements for 2 weeks before a bone density scan"). Deliberately no FK to
// test_catalog, matching how patient_vaccination stores its own name rather than
// joining back to a reference table — the catalog is a starting point, not a permanent
// link. category is denormalized here too (not looked up via a join) purely so the
// tracked list can show the right icon without needing the catalog loaded.
class PatientTest {
  final int? id; // null until saved once
  final String name;
  final String? category;
  DateTime? lastDone;
  DateTime? nextDue;
  String? notes; // special instructions from the lab, e.g. prep restrictions

  PatientTest({this.id, required this.name, this.category, this.lastDone, this.nextDue, this.notes});

  IconData get icon => iconForTestCategory(category);

  factory PatientTest.fromRow(Map<String, dynamic> row) {
    return PatientTest(
      id: row['id'] as int?,
      name: row['name'] as String,
      category: row['category'] as String?,
      lastDone: row['last_done'] != null ? DateTime.tryParse(row['last_done'] as String) : null,
      nextDue: row['next_due'] != null ? DateTime.tryParse(row['next_due'] as String) : null,
      notes: row['notes'] as String?,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'name': name,
      'category': category,
      'last_done': lastDone?.toIso8601String(),
      'next_due': nextDue?.toIso8601String(),
      'notes': notes,
    };
  }
}
