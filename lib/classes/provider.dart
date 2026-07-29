import 'package:flutter/cupertino.dart';
import 'package:triage/classes/specialities.dart';

import 'country_codes.dart';

enum DepartmentColors { blue, green, cyan, purple, red, orange, brown, darkPurple, slateGray, indigo, pink }

class Provider {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String position;
  final DateTime hireDate;
  final bool isSpecialist;
  final Specialities speciality;
  final bool onCall;
  final String department;
  final String? pager;
  final String phone;
  final String street;
  final String code;
  final String city;
  final String provOrState;
  final String country;
  final String? countryIso;
  final DepartmentColors color;
  final IconData icon;

  const Provider({
    required this.id,
    required this.speciality,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.position,
    required this.hireDate,
    required this.isSpecialist,
    required this.onCall,
    this.pager,
    required this.color,
    required this.department,
    required this.phone,
    required this.icon,
    required this.street,
    required this.code,
    required this.city,
    required this.provOrState,
    required this.country,
    this.countryIso,
  });
  String get address {
    return '$street, $city, $provOrState, $code, $country';
  }

  factory Provider.fromJson(Map<String, dynamic> json) {
    String positionRaw = json["position"] ?? "General Practice";
    Specialities speciality = specialities[positionRaw] ?? Specialities.generalPractice;
    String countryName = json["country"] ?? "Canada";
    String countryISO = countryCodes[countryName]?.isoA2 ?? "CA";
    return Provider(
      icon: speciality.icon,
      id: json["provider_uuid"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      email: json["personal_email"] ?? "",
      gender: json["gender"],
      position: json["position"],
      hireDate: DateTime.now().subtract(Duration(days: 365)),
      isSpecialist: (json["is_specialist"] == 1),
      speciality: speciality,
      onCall: (json["on_call"] == 1),
      pager: json["pager"] ?? "",
      color: speciality.color,
      department: speciality.name,
      phone: json["personal_phone"] ?? "",
      street: json["street"] ?? "",
      city: json["city"] ?? "",
      provOrState: json["pr_st"] ?? "",
      code: json["code"] ?? "",
      country: json["country"] ?? "",
      countryIso: countryISO,
    );
  }

  // Helper to convert back to Map for your SQLite insert methods
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "gender": gender,
      "position": position,
      "is_specialist": isSpecialist ? 1 : 0,
      "pager": pager,
      "phone": phone,
    };
  }
}
