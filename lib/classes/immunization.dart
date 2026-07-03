import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/date_time_utilities.dart';

final Map<String, String> codeToName = {'CA': 'Canada', 'MX': 'Mexico', 'US': 'United States of America'};

class Vaccine {
  final String name;
  final String recommendation;
  final String protection;
  final int interval;
  DateTime? takenOn;
  int yearsAgo;
  String policy;
  bool taken;

  Vaccine({
    required this.name,
    required this.recommendation,
    required this.interval,
    this.yearsAgo = 0,
    this.taken = false,
    this.takenOn,
    this.policy = "",
    this.protection = "",
  });

  factory Vaccine.fromMap(Map<String, dynamic> item) {
    return Vaccine(
      name: item["name"],
      recommendation: item["recommendation"],
      interval: item["interval_between_shots"],
    );
  }

  void setPatientRecord(PatientVaccine pv) {
    if (pv.name == name) {
      taken = true;
      takenOn = pv.received;
    }
  }

  DateTime? get expirationDate {
    return takenOn != null ? DateTime(takenOn!.year + interval, takenOn!.month, takenOn!.day) : null;
  }

  int get yearsSince {
    return takenOn != null ? DateTime.now().year - takenOn!.year : 0;
  }

  String get formattedVaccineDate {
    return takenOn == null ? "" : DateFormat('MMMM d, y').format(takenOn!);
  }

  String get formattedExpirationDate {
    return takenOn == null ? "" : DateFormat('MMMM d, y').format(expirationDate!);
  }

  String get reminder {
    int yrs = yearsSince;
    String rem = yrs > 1 ? "($yrs years ago)." : "($yrs year ago).";

    rem = overdue
        ? interval > 1
              ? "$rem\nIt is recommended to take this vaccine every $interval year(s)."
              : "It is recommended to take this vaccine every year."
        : "$rem\nNext vaccination on:$formattedExpirationDate.";
    return rem;
  }

  bool get overdue {
    // Only check if it was actually taken
    if (!taken || takenOn == null) return false;
    DateTime? expDate = expirationDate;
    // It is overdue if the expiration date is before today
    return expDate == null ? false : expDate.isBefore(DateTime.now());
  }
}

class ImmunizationGroup {
  final String group;
  final List<Vaccine> vaccines;

  ImmunizationGroup({required this.group, required this.vaccines});

  factory ImmunizationGroup.fromJson(Map<String, dynamic> json) {
    var list = json['vaccines'] as List? ?? [];
    List<Vaccine> vaccineList = list.map((i) => Vaccine.fromMap(i)).toList();
    return ImmunizationGroup(group: json['group'], vaccines: vaccineList);
  }
}

class CountrySchedule {
  final String country;
  final List<ImmunizationGroup> groups;

  CountrySchedule({required this.country, required this.groups});

  factory CountrySchedule.fromJson(Map<String, dynamic> json) {
    var list = json['groups'] as List? ?? [];
    List<ImmunizationGroup> groupList = list.map((i) => ImmunizationGroup.fromJson(i)).toList();
    return CountrySchedule(country: json['country'], groups: groupList);
  }
}

class DeviceLocaleHelper {
  static String getCountryCode() {
    final ui.Locale locale = ui.PlatformDispatcher.instance.locale;
    return locale.countryCode ?? 'US';
  }
}

class PatientVaccine {
  final String name;
  final String protection;
  DateTime? received;
  int yearsAgo;
  bool taken;

  PatientVaccine({required this.name, required this.protection, required this.received, this.yearsAgo = 0})
    : taken = true;

  factory PatientVaccine.fromMap(Map<String, dynamic> item) {
    // Handle nulls safely
    DateTime? receivedDate = item['received'] != null ? DTUtilities.sqliteToDart(item['received']) : null;

    // Use years_ago if present, otherwise calculate from date, otherwise null
    int yearsSince = item['years_ago'] ?? (receivedDate != null ? DTUtilities.calculateYearsSince(receivedDate) : null);

    return PatientVaccine(
      name: item['name'] as String,
      protection: item['protection'] as String,
      received: receivedDate,
      yearsAgo: yearsSince,
    );
  }
}

class ImmunizationService {
  final List<CountrySchedule> _schedules;
  Map<String, PatientVaccine> patientImmunizations = {};
  ImmunizationService._(this._schedules);

  static Future<ImmunizationService> create() async {
    final String jsonString = await rootBundle.loadString('assets/conditions/immunizations.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    final schedules = jsonData.map((item) => CountrySchedule.fromJson(item)).toList();
    return ImmunizationService._(schedules);
  }

  // Resolves the detected country code to the dataset
  CountrySchedule? getScheduleForDevice() {
    String countryCode = DeviceLocaleHelper.getCountryCode();

    String? countryName = codeToName[countryCode.toUpperCase()];

    return _schedules.firstWhere(
      (s) => s.country.toLowerCase() == (countryName ?? "").toLowerCase(),
      orElse: () => _schedules.first, // Default to first if not found
    );
  }

  Future<Map<String, PatientVaccine>> getPatientVaccinations(String patientUuid) async {
    // Access the singleton instance
    List<Map<String, dynamic>> rawVaccines = await DatabaseManager().getPatientVaccinations(patientUuid);

    // Transform the list into a Map keyed by vaccine name
    // Note: Using name as the key assumes names are unique in your JSON schema
    Map<String, PatientVaccine> vaccineMap = {
      for (var item in rawVaccines) item['name'] as String: PatientVaccine.fromMap(item),
    };
    patientImmunizations = vaccineMap;
    return vaccineMap;
  }

  void resolvePatientImmunizations(Map<String, PatientVaccine> patientVaccines, CountrySchedule schedule) {
    for (ImmunizationGroup group in schedule.groups) {
      for (Vaccine vaccine in group.vaccines) {
        PatientVaccine? pv = patientVaccines[vaccine.name];
        if (pv != null) {
          vaccine.setPatientRecord(pv);
        }
      }
    }
  }

  Future<int> insertVaccination(String patientUuid, String name, String protection, DateTime? received) {
    patientImmunizations[name] = PatientVaccine(name: name, protection: protection, received: received);
    return DatabaseManager().insertVaccination(patientUuid, name, protection, received);
  }

  Future<int> deleteVaccination(String name, String patientUuid) {
    patientImmunizations.remove(name);
    return DatabaseManager().deleteVaccination(name, patientUuid);
  }
}
