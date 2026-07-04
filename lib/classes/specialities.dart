import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/staff.dart';

enum Specialities {
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
}

Map<String, Specialities> specialities = {
  "Audiologist": Specialities.audiology,
  "Cardiologist": Specialities.cardiology,
  "Pulmonologist": Specialities.pulmonology,
  "Oncologist": Specialities.oncology,
  "Pediatrician": Specialities.pediatrics,
  "Immunologist": Specialities.immunology,
  "Respirologist": Specialities.respirology,
  "Respiratory Nurse": Specialities.respirology,
  "Neurologist": Specialities.neurology,
  "Psychiatrist": Specialities.psychiatry,
  "Geriatric Psychiatrist": Specialities.psychiatry,
  "Psychiatric Nurse": Specialities.psychiatry,
  "Gynecologist": Specialities.gynecology,
  "Obstetrician": Specialities.obstetrics,
  "Medical Doctor": Specialities.generalPractice,
  "Medical Professional": Specialities.medicine,
  "Endocrinologist": Specialities.endocrinology,
  "Gastroenterologist": Specialities.gastroenterology,
  "Ophthalmologist": Specialities.ophthalmology,
  "Orthopedist": Specialities.orthopedics,
  "Physical Therapist": Specialities.physicalTherapy,
  "Podiatrist": Specialities.podiatry,
  "Rheumatologist": Specialities.rheumatology,
  "Urologist": Specialities.urology,
  "Dermatologist": Specialities.dermatology,
  "Audiologists": Specialities.audiology,
  "Cardiologists": Specialities.cardiology,
  "Pulmonologists": Specialities.pulmonology,
  "Oncologists": Specialities.oncology,
  "Oncology Nurse": Specialities.oncology,
  "Oncologist Nurse": Specialities.oncology,
  "Pediatricians": Specialities.pediatrics,
  "Professional": Specialities.medicine,
  "Physician": Specialities.generalPractice,
  "Attending Physician": Specialities.generalPractice,
  "Podiatrists": Specialities.podiatry,
  "Rheumatologists": Specialities.rheumatology,
  "Phlebotomist": Specialities.phlebotomy,
  "Intensivist": Specialities.intensiveCare,
  "Psychometrist": Specialities.psychometry,
  "Clinical Psychologist": Specialities.psychometry,
  "Psychologist": Specialities.psychometry,
  "Surgeon": Specialities.surgery,
  "Surgical Technologist": Specialities.surgery,
  "Operating Room Nurse": Specialities.surgery,
  "Radiologist": Specialities.imaging,
  "Radiology Technician": Specialities.imaging,
  "Radiation Technologist": Specialities.imaging,
  "Medical Laboratory Technologist": Specialities.medicalLab,
  "Anesthesiologist": Specialities.anesthesiology,
  "Biomedical Engineer": Specialities.biomedicalEngineering,
  "Biomechanical Engineer": Specialities.biomedicalEngineering,
  "Certified Nurse-MidWife": Specialities.neonatology,
  "Neonatologist": Specialities.neonatology,
  "Neonatal Nurse": Specialities.neonatology,
  "Neonatal ICU Nurse": Specialities.neonatology,
  "Infectious Disease Specialist": Specialities.infectiousDisease,
  "Microbiologist": Specialities.microBiology,
  "Nutritionist": Specialities.nutrition,
  "Sonographist": Specialities.sonography,
  "Diagnostic Medical Sonographer": Specialities.sonography,
  "Emergency Medicine Physician": Specialities.emergency,
  "Emergency Medicine Nurse": Specialities.emergency,
  "Emergency Physician": Specialities.emergency,
  "Emergency Nurse": Specialities.emergency,
  "Pharmacist": Specialities.pharmacology,
  "Pharmacy Technician": Specialities.pharmacology,
  "Pharmacologist": Specialities.pharmacology,
  "Clinical Pharmacist": Specialities.pharmacology,
};

extension SpecialtyName on Specialities {
  String get name {
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
    }
  }
}

extension SpecialtyDesignation on Specialities {
  String get designation {
    switch (this) {
      case Specialities.cardiology:
        return "Cardiologist";
      case Specialities.pulmonology:
        return "Pulmonologist";
      case Specialities.oncology:
        return "Oncologist";
      case Specialities.pediatrics:
        return "Pediatrician";
      case Specialities.immunology:
        return "Immunologist";
      case Specialities.respirology:
        return "Respirologist";
      case Specialities.neurology:
        return "Neurologist";
      case Specialities.obstetricsAndGynecology:
        return "Gynecologist";
      case Specialities.psychiatry:
        return "Psychiatrist";
      case Specialities.gynecology:
        return "Gynecologist";
      case Specialities.obstetrics:
        return "Obstetrician";
      case Specialities.generalPractice:
        return "Medical Doctor";
      case Specialities.medicine:
        return "Medical Professional";
      case Specialities.endocrinology:
        return "Endocrinologist";
      case Specialities.gastroenterology:
        return "Gastroenterologist";
      case Specialities.ophthalmology:
        return "Ophthalmologist";
      case Specialities.orthopedics:
        return "Orthopedist";
      case Specialities.physicalTherapy:
        return "Physical Therapist";
      case Specialities.podiatry:
        return "Podiatrist";
      case Specialities.rheumatology:
        return "Rheumatologist";
      case Specialities.urology:
        return "Urologist";
      case Specialities.dermatology:
        return "Dermatologist";
      case Specialities.audiology:
        return "Audiologist";
      case Specialities.phlebotomy:
        return "Phlebotomist";
      case Specialities.intensiveCare:
        return "Intensivist";
      case Specialities.psychometry:
        return "Psychometrist";
      case Specialities.surgery:
        return "Surgeon";
      case Specialities.imaging:
        return "Radiologist";
      case Specialities.medicalLab:
        return "Medical Lab Technologist";
      case Specialities.anesthesiology:
        return "Anesthesiologist";
      case Specialities.biomedicalEngineering:
        return "Biomedical Engineer";
      case Specialities.neonatology:
        return "Neonatologist";
      case Specialities.infectiousDisease:
        return "Infectious Disease Specialist";
      case Specialities.microBiology:
        return "Microbiologist";
      case Specialities.nutrition:
        return "Nutritionist";
      case Specialities.sonography:
        return "Sonographist";
      case Specialities.emergency:
        return "Emergency";
      case Specialities.pharmacology:
        return "Pharmacist";
    }
  }
}

extension SpecialtyIcon on Specialities {
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
    }
  }
}

extension SpecializationColor on Specialities {
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
    }
  }
}
