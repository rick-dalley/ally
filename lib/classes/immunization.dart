import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/date_time_utilities.dart';
import 'package:triage/classes/vaccine.dart';

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
  final int id;
  final String name;
  final String protection;
  final DateTime? received;
  final int? yearsAgo;

  const PatientVaccine({
    required this.id,
    required this.name,
    required this.protection,
    required this.received,
    required this.yearsAgo,
  });

  factory PatientVaccine.fromMap(Map<String, dynamic> item) {
    // Handle nulls safely
    DateTime? receivedDate = item['received'] != null ? DTUtilities.sqliteToDart(item['received']) : null;

    // Use years_ago if present, otherwise calculate from date, otherwise null
    int? yearsSince =
        item['years_ago'] ?? (receivedDate != null ? DTUtilities.calculateYearsSince(receivedDate) : null);

    return PatientVaccine(
      id: item['id'] as int,
      name: item['name'] as String,
      protection: item['protection'] as String,
      received: receivedDate,
      yearsAgo: yearsSince,
    );
  }
}

class ImmunizationService {
  final List<CountrySchedule> _schedules;

  ImmunizationService._(this._schedules);

  static Future<ImmunizationService> create() async {
    final String jsonString = await rootBundle.loadString('assets/conditions/immunizations.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    final schedules = jsonData.map((item) => CountrySchedule.fromJson(item)).toList();
    return ImmunizationService._(schedules);
  }

  // Resolves the detected country code to your dataset
  CountrySchedule? getScheduleForDevice() {
    String countryCode = DeviceLocaleHelper.getCountryCode();

    // Map ISO codes to your JSON names
    final Map<String, String> codeToName = {'CA': 'Canada', 'MX': 'Mexico', 'US': 'United States of America'};

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

    return vaccineMap;
  }

  Future<int> insertVaccination(String patientUuid, String name, String protection, DateTime? received) {
    return DatabaseManager().insertVaccination(patientUuid, name, protection, received);
  }

  Future<int> deleteVaccination(int id, String patientUuid) {
    return DatabaseManager().deleteVaccination(id, patientUuid);
  }
}
