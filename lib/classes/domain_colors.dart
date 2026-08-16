import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// One color per app feature — the whole point is that a patient recognizes "this is
// Supplies" or "this is a Prescriptions reminder" by color alone, before reading a
// word, the same way the body-system palette already does for conditions/allergies.
// Deliberately its own palette, not reusing Carbon's semantic colors (danger/success/
// warning — those mean state/severity, not "which feature") or medical_category_colors
// (those mean body system, not "which feature") — see medical_category_colors.dart for
// the fuller reasoning on why these stay three separate languages. Every icon here
// matches the one already established for that domain elsewhere in the app (the hub
// tile, the reminder) rather than picking a new one.
enum AppDomain {
  conditions,
  diary,
  immunizations,
  prescriptions,
  symptoms,
  tests,
  reports,
  allergies,
  eyeCare,
  supplies,
  questionnaires,
  careTeam,
  metrics;

  Color get color {
    switch (this) {
      case AppDomain.conditions:
        return const Color(0xFF5C6BC0); // indigo
      case AppDomain.diary:
        return const Color(0xFF8D6E63); // warm taupe
      case AppDomain.immunizations:
        return const Color(0xFF26A69A); // teal-green
      case AppDomain.prescriptions:
        return const Color(0xFF42A5F5); // sky blue
      case AppDomain.symptoms:
        return const Color(0xFFEC407A); // pink-magenta
      case AppDomain.tests:
        return const Color(0xFF7E57C2); // violet
      case AppDomain.reports:
        return const Color(0xFF546E7A); // slate
      case AppDomain.allergies:
        return const Color(0xFFEF6C00); // deep orange
      case AppDomain.eyeCare:
        return const Color(0xFF00ACC1); // cyan
      case AppDomain.supplies:
        return const Color(0xFF7CB342); // fresh green
      case AppDomain.questionnaires:
        return const Color(0xFFAB47BC); // light purple
      case AppDomain.careTeam:
        return const Color(0xFF6D4C41); // dark brown
      case AppDomain.metrics:
        return const Color(0xFFFFA000); // amber
    }
  }

  IconData get icon {
    switch (this) {
      case AppDomain.conditions:
        return Symbols.diagnosis_sharp;
      case AppDomain.diary:
        return Symbols.clinical_notes_sharp;
      case AppDomain.immunizations:
        // Not vaccines_sharp — that glyph renders blank on Android release builds
        // despite being present in the tree-shaken font subset.
        return Symbols.vaccines;
      case AppDomain.prescriptions:
        return Symbols.medication_sharp;
      case AppDomain.symptoms:
        return Symbols.symptoms;
      case AppDomain.tests:
        return Symbols.lab_panel;
      case AppDomain.reports:
        return Symbols.description;
      case AppDomain.allergies:
        return Symbols.allergy;
      case AppDomain.eyeCare:
        return Symbols.ophthalmology;
      case AppDomain.supplies:
        return Symbols.inventory_2;
      case AppDomain.questionnaires:
        return Symbols.ballot_sharp;
      case AppDomain.careTeam:
        return Symbols.diversity_4;
      case AppDomain.metrics:
        return Symbols.health_metrics;
    }
  }
}
