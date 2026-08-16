import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'carbon_color_constants.dart';

// The body-system palette — originally built for Existing Medical Conditions, now the
// shared source of truth for anything else that's naturally categorized by medical
// specialty (provider cards, by the doctor's own specialty). Deliberately a separate
// palette from the app's Carbon semantic colors (danger/success/warning) and from the
// app-domain identity palette (domain_colors.dart) — three different things being
// colored (a body system, a severity/state, a feature of the app), so three different
// color languages that must never share a hue, or the whole point of using color as
// information collapses back into noise.
class MedicalCategory {
  final IconData iconData;
  final Color color;
  final Color textColor;
  const MedicalCategory({required this.iconData, required this.color, required this.textColor});
}

const Color _onColor = Colors.white;

final Map<String, MedicalCategory> medicalCategoryColors = {
  "Cardiovascular": MedicalCategory(iconData: Symbols.cardiology, color: Color(0xFFBA0000), textColor: _onColor),
  "Dermatological": MedicalCategory(iconData: Symbols.dermatology, color: Color(0xFFBA5D00), textColor: _onColor),
  "Gastrointestinal": MedicalCategory(iconData: Symbols.gastroenterology, color: Color(0xFF64008C), textColor: _onColor),
  "Infectious and Immunological": MedicalCategory(
    iconData: Symbols.microbiology,
    color: Color(0xFFBA8002),
    textColor: _onColor,
  ),
  "Mental and Behavioral Health": MedicalCategory(
    iconData: Symbols.psychiatry,
    color: Color(0xFF187303),
    textColor: _onColor,
  ),
  "Metabolic & Endocrine": MedicalCategory(iconData: Symbols.metabolism, color: Color(0xFF730350), textColor: _onColor),
  "Musculoskeletal": MedicalCategory(iconData: Symbols.orthopedics, color: Color(0xFF636363), textColor: _onColor),
  "Neurological": MedicalCategory(iconData: Symbols.neurology, color: Color(0xFF215A8A), textColor: _onColor),
  "Respiratory": MedicalCategory(iconData: Symbols.pulmonology, color: Color(0xFF0298BA), textColor: _onColor),
  "Urological and Reproductive": MedicalCategory(
    iconData: Symbols.urology,
    color: Color(0xFF8A346C),
    textColor: _onColor,
  ),
  "Custom": MedicalCategory(iconData: Symbols.medical_information, color: carbonColorButtonPrimary, textColor: _onColor),
};

final MedicalCategory _generalCategory = MedicalCategory(
  iconData: Symbols.stethoscope,
  color: const Color(0xFF525252),
  textColor: _onColor,
);

// Keyword match against a provider's free-text specialty/position — there's no
// structured specialty enum in this app, providers are entered as free text, so this is
// necessarily approximate (same honesty as the drug-allergy name matching elsewhere:
// best-effort, not a clinical taxonomy). Falls back to a neutral gray for anything that
// doesn't match a body system at all (a family doctor, a general practitioner) rather
// than guessing wrong.
MedicalCategory categoryForSpecialty(String? specialty) {
  if (specialty == null || specialty.trim().isEmpty) return _generalCategory;
  final String s = specialty.toLowerCase();

  const Map<String, List<String>> keywords = {
    "Cardiovascular": ["cardio", "heart"],
    "Dermatological": ["dermat", "skin"],
    "Gastrointestinal": ["gastro", "hepat", "colon", "bowel"],
    "Infectious and Immunological": ["infecti", "immunolog", "allerg"],
    "Mental and Behavioral Health": ["psychiatr", "psycholog", "mental", "behavioral", "counsel", "therap"],
    "Metabolic & Endocrine": ["endocrin", "diabet", "metabol", "thyroid"],
    "Musculoskeletal": ["ortho", "rheumatolog", "musculoskeletal", "physio", "physical therap"],
    "Neurological": ["neuro"],
    "Respiratory": ["pulmonolog", "respiratory", "lung"],
    "Urological and Reproductive": ["urolog", "gynecolog", "obstetric", "reproduct"],
  };

  for (final entry in keywords.entries) {
    if (entry.value.any((k) => s.contains(k))) {
      return medicalCategoryColors[entry.key] ?? _generalCategory;
    }
  }
  return _generalCategory;
}
