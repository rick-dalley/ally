import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/listable.dart';

enum DepartmentColors { blue, green, cyan, purple, red, orange, brown, darkPurple, slateGray, indigo, pink, grey }

extension DepartmentColorsColor on DepartmentColors {
  Color get color {
    switch (this) {
      case DepartmentColors.blue:
        return Colors.blue;
      case DepartmentColors.green:
        return Colors.green;
      case DepartmentColors.cyan:
        return Colors.cyan;
      case DepartmentColors.purple:
        return Colors.purple;
      case DepartmentColors.red:
        return Colors.red;
      case DepartmentColors.orange:
        return Colors.deepOrange;
      case DepartmentColors.brown:
        return Colors.brown;
      case DepartmentColors.darkPurple:
        return Colors.deepPurple;
      case DepartmentColors.slateGray:
        return Colors.blueGrey;
      case DepartmentColors.indigo:
        return Colors.indigo;
      case DepartmentColors.pink:
        return Colors.pink;
      case DepartmentColors.grey:
        return Colors.grey;
    }
  }
}

enum Specialities implements Listable {
  medicine,
  audiology,
  cardiology,
  dermatology,
  pulmonology,
  oncology,
  pediatrics,
  neonatology,
  immunology,
  respirology,
  neurology,
  obstetricsAndGynecology,
  gynecology,
  obstetrics,
  psychiatry,
  endocrinology,
  generalPractice,
  gastroenterology,
  ophthalmology,
  orthopedics,
  physicalTherapy,
  podiatry,
  rheumatology,
  urology,
  phlebotomy,
  intensiveCare,
  psychometry,
  surgery,
  imaging,
  medicalLab,
  anesthesiology,
  biomedicalEngineering,
  infectiousDisease,
  microBiology,
  nutrition,
  sonography,
  emergency,
  pharmacology,
  other;

  @override
  String get description {
    switch (this) {
      case Specialities.medicine:
        return "Professional";
      case Specialities.cardiology:
        return "Cardiology";
      case Specialities.pulmonology:
        return "Pulmonology";
      case Specialities.oncology:
        return "Oncology";
      case Specialities.pediatrics:
        return "Pediatrics";
      case Specialities.immunology:
        return "Immunology";
      case Specialities.respirology:
        return "Respirology";
      case Specialities.neurology:
        return "Neurology";
      case Specialities.obstetricsAndGynecology:
        return "Obstetrics And Gynecology";
      case Specialities.psychiatry:
        return "Psychiatry";
      case Specialities.gynecology:
        return "Gynecology";
      case Specialities.obstetrics:
        return "Obstetrics";
      case Specialities.endocrinology:
        return "Endocrinology";
      case Specialities.generalPractice:
        return "General Practice";
      case Specialities.gastroenterology:
        return "Gastroenterology";
      case Specialities.ophthalmology:
        return "Ophthalmology";
      case Specialities.orthopedics:
        return "Orthopedics";
      case Specialities.physicalTherapy:
        return "Physical Therapy";
      case Specialities.podiatry:
        return "Podiatry";
      case Specialities.rheumatology:
        return "Rheumatology";
      case Specialities.urology:
        return "Urology";
      case Specialities.dermatology:
        return "Dermatology";
      case Specialities.audiology:
        return "Audiology";
      case Specialities.phlebotomy:
        return "Phlebotomy";
      case Specialities.intensiveCare:
        return "Intensive Care";
      case Specialities.psychometry:
        return "Psychometry";
      case Specialities.surgery:
        return "Surgery";
      case Specialities.imaging:
        return "Imaging";
      case Specialities.medicalLab:
        return "Medical Lab";
      case Specialities.anesthesiology:
        return "Anesthesiology";
      case Specialities.biomedicalEngineering:
        return "Biomedical Engineering";
      case Specialities.neonatology:
        return "Neonatal Care";
      case Specialities.infectiousDisease:
        return "Infectious Disease";
      case Specialities.microBiology:
        return "Microbiology";
      case Specialities.nutrition:
        return "Nutrition";
      case Specialities.sonography:
        return "Sonography";
      case Specialities.emergency:
        return "Emergency";
      case Specialities.pharmacology:
        return "Pharmacology";
      case Specialities.other:
        return "Other";
    }
  }

  @override
  String get label {
    switch (this) {
      case Specialities.medicine:
        return "Professional";
      case Specialities.cardiology:
        return "Cardiology";
      case Specialities.pulmonology:
        return "Pulmonology";
      case Specialities.oncology:
        return "Oncology";
      case Specialities.pediatrics:
        return "Pediatrics";
      case Specialities.immunology:
        return "Immunology";
      case Specialities.respirology:
        return "Respirology";
      case Specialities.neurology:
        return "Neurology";
      case Specialities.obstetricsAndGynecology:
        return "Obstetrics And Gynecology";
      case Specialities.psychiatry:
        return "Psychiatry";
      case Specialities.gynecology:
        return "Gynecology";
      case Specialities.obstetrics:
        return "Obstetrics";
      case Specialities.endocrinology:
        return "Endocrinology";
      case Specialities.generalPractice:
        return "General Practice";
      case Specialities.gastroenterology:
        return "Gastroenterology";
      case Specialities.ophthalmology:
        return "Ophthalmology";
      case Specialities.orthopedics:
        return "Orthopedics";
      case Specialities.physicalTherapy:
        return "Physical Therapy";
      case Specialities.podiatry:
        return "Podiatry";
      case Specialities.rheumatology:
        return "Rheumatology";
      case Specialities.urology:
        return "Urology";
      case Specialities.dermatology:
        return "Dermatology";
      case Specialities.audiology:
        return "Audiology";
      case Specialities.phlebotomy:
        return "Phlebotomy";
      case Specialities.intensiveCare:
        return "Intensive Care";
      case Specialities.psychometry:
        return "Psychometry";
      case Specialities.surgery:
        return "Surgery";
      case Specialities.imaging:
        return "Imaging";
      case Specialities.medicalLab:
        return "Medical Lab";
      case Specialities.anesthesiology:
        return "Anesthesiology";
      case Specialities.biomedicalEngineering:
        return "Biomedical Engineering";
      case Specialities.neonatology:
        return "Neonatal Care";
      case Specialities.infectiousDisease:
        return "Infectious Disease";
      case Specialities.microBiology:
        return "Microbiology";
      case Specialities.nutrition:
        return "Nutrition";
      case Specialities.sonography:
        return "Sonography";
      case Specialities.emergency:
        return "Emergency";
      case Specialities.pharmacology:
        return "Pharmacology";
      case Specialities.other:
        return "Other";
    }
  }

  IconData get icon {
    switch (this) {
      case Specialities.cardiology:
        return Symbols.cardiology;
      case Specialities.pulmonology:
        return Symbols.pulmonology;
      case Specialities.oncology:
        return Symbols.oncology;
      case Specialities.pediatrics:
        return Symbols.pediatrics;
      case Specialities.immunology:
        return Symbols.immunology;
      case Specialities.respirology:
        return Symbols.respiratory_rate;
      case Specialities.neurology:
        return Symbols.neurology;
      case Specialities.obstetricsAndGynecology:
        return Symbols.gynecology;
      case Specialities.psychiatry:
        return Symbols.psychiatry;
      case Specialities.gynecology:
        return Symbols.gynecology;
      case Specialities.obstetrics:
        return Symbols.pregnancy;
      case Specialities.generalPractice:
        return Symbols.stethoscope;
      case Specialities.medicine:
        return Symbols.medical_services;
      case Specialities.endocrinology:
        return Symbols.endocrinology;
      case Specialities.gastroenterology:
        return Symbols.gastroenterology;
      case Specialities.ophthalmology:
        return Symbols.ophthalmology;
      case Specialities.orthopedics:
        return Symbols.orthopedics;
      case Specialities.physicalTherapy:
        return Symbols.physical_therapy;
      case Specialities.podiatry:
        return Symbols.podiatry;
      case Specialities.rheumatology:
        return Symbols.rheumatology;
      case Specialities.urology:
        return Symbols.urology;
      case Specialities.dermatology:
        return Symbols.dermatology;
      case Specialities.audiology:
        return Symbols.hearing;
      case Specialities.phlebotomy:
        return Symbols.bloodtype;
      case Specialities.intensiveCare:
        return Symbols.ventilator;
      case Specialities.psychometry:
        return Symbols.psychology;
      case Specialities.surgery:
        return Symbols.surgical;
      case Specialities.imaging:
        return Symbols.hand_bones;
      case Specialities.medicalLab:
        return Symbols.lab_panel;
      case Specialities.anesthesiology:
        return Symbols.masks;
      case Specialities.biomedicalEngineering:
        return Symbols.biotech;
      case Specialities.neonatology:
        return Symbols.baby_changing_station;
      case Specialities.infectiousDisease:
        return Symbols.coronavirus;
      case Specialities.microBiology:
        return Symbols.microbiology;
      case Specialities.nutrition:
        return Symbols.nutrition;
      case Specialities.sonography:
        return Symbols.waves;
      case Specialities.emergency:
        return Symbols.emergency;
      case Specialities.pharmacology:
        return Symbols.medication;
      case Specialities.other:
        return Symbols.unknown_2;
    }
  }

  DepartmentColors get color {
    switch (this) {
      case Specialities.emergency:
      case Specialities.intensiveCare:
      case Specialities.cardiology:
      case Specialities.phlebotomy:
        return DepartmentColors.red;
      case Specialities.obstetricsAndGynecology:
      case Specialities.obstetrics:
      case Specialities.pediatrics:
      case Specialities.gynecology:
      case Specialities.neonatology:
        return DepartmentColors.pink;
      case Specialities.immunology:
      case Specialities.infectiousDisease:
      case Specialities.microBiology:
        return DepartmentColors.brown;
      case Specialities.endocrinology:
      case Specialities.respirology:
      case Specialities.pulmonology:
      case Specialities.urology:
        return DepartmentColors.slateGray;
      case Specialities.generalPractice:
      case Specialities.gastroenterology:
      case Specialities.podiatry:
      case Specialities.orthopedics:
        return DepartmentColors.cyan;
      case Specialities.physicalTherapy:
      case Specialities.rheumatology:
      case Specialities.ophthalmology:
      case Specialities.audiology:
        return DepartmentColors.darkPurple;
      case Specialities.neurology:
      case Specialities.psychometry:
      case Specialities.psychiatry:
        return DepartmentColors.orange;
      case Specialities.imaging:
      case Specialities.medicalLab:
      case Specialities.anesthesiology:
      case Specialities.biomedicalEngineering:
        return DepartmentColors.blue;
      case Specialities.nutrition:
      case Specialities.dermatology:
      case Specialities.medicine:
      case Specialities.surgery:
        return DepartmentColors.green;
      case Specialities.sonography:
      case Specialities.pharmacology:
      case Specialities.oncology:
        return DepartmentColors.indigo;
      case Specialities.other:
        return DepartmentColors.grey;
    }
  }
}
