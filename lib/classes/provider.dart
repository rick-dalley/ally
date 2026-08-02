import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/metric_value.dart';
import 'package:triage/classes/specialities.dart';

import 'country_codes.dart';

enum DepartmentColors { blue, green, cyan, purple, red, orange, brown, darkPurple, slateGray, indigo, pink }

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
    }
  }
}

extension DepartmentPhotos on DepartmentColors {
  String get photoUrl {
    switch (this) {
      case DepartmentColors.blue:
        return "assets/images/faces/staff/dr_face_1.png";
      case DepartmentColors.green:
        return "assets/images/faces/staff/dr_face_2.png";
      case DepartmentColors.cyan:
        return "assets/images/faces/staff/emerg_face_1.png";
      case DepartmentColors.purple:
        return "assets/images/faces/staff/emerg_face_2.png";
      case DepartmentColors.red:
        return "assets/images/faces/staff/psych_face_2.png";
      case DepartmentColors.orange:
        return "assets/images/faces/staff/psych_nurse_1.png";
      case DepartmentColors.brown:
        return "assets/images/faces/staff/psych_nurse_2.png";
      case DepartmentColors.darkPurple:
        return "assets/images/faces/staff/prof_face_1.png";
      case DepartmentColors.slateGray:
        return "assets/images/faces/staff/prof_face_2.png";
      case DepartmentColors.indigo:
        return "assets/images/faces/staff/prof_yng_1.png";
      case DepartmentColors.pink:
        return "assets/images/faces/staff/prof_old_1.png";
    }

    // return "assets/images/faces/staff/nurse_face_1.png";
    //   return "assets/images/faces/staff/nurse_face_2.png";
    //   return "assets/images/faces/staff/police_face_1.png";
    //   return"assets/images/faces/staff/police_face_2.png";
  }
}

class Provider {
  final String id;
  String patientUuid;
  NetworkImage? image;
  String? firstName;
  String? lastName;
  final String? email;
  final String? gender;
  final String? position;
  final DateTime? hireDate;
  final bool? isSpecialist;
  final Specialities? speciality;
  final bool? onCall;
  final String? department;
  final String? pager;
  final String? phone;
  final String? street;
  final String? code;
  final String? city;
  final String? provOrState;
  final String? country;
  final String? countryIso;
  final DepartmentColors? color;
  late IconData? icon;

  Provider({
    required this.id,
    required this.patientUuid,
    this.image,
    this.speciality,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.position,
    this.hireDate,
    this.isSpecialist,
    this.onCall,
    this.pager,
    this.color,
    this.department,
    this.phone,
    this.icon,
    this.street,
    this.code,
    this.city,
    this.provOrState,
    this.country,
    this.countryIso,
  });
  String get address {
    return '$street, $city, $provOrState, $code, $country';
  }

  factory Provider.fromContact(Contact contact, String patientUuid) {
    String new_id = uuid.toString();
    String fullName = contact.fullName ?? '';
    // Split the string by spaces, removing any empty strings if there are double spaces
    List<String> nameParts = fullName.trim().split(RegExp(r'\s+'));

    String firstName = '';
    String lastName = '';

    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      if (nameParts.length == 1) {
        // If only one word was provided, put it in first name (or handle as you prefer)
        firstName = nameParts[0];
      } else {
        // First part is the first name
        firstName = nameParts[0];
        // Everything else combined becomes the last name (handles middle names/multi-part surnames)
        lastName = nameParts.sublist(1).join(' ');
      }
    }
    return Provider(
      id: new_id,
      patientUuid: patientUuid,
      firstName: firstName,
      lastName: lastName,
      phone: contact.selectedPhoneNumber,
    );
  }
  factory Provider.fromJson(Map<String, dynamic> json) {
    String positionRaw = json["position"] ?? "General Practice";
    Specialities speciality = specialities[positionRaw] ?? Specialities.generalPractice;
    String countryName = json["country"] ?? "Canada";
    String countryISO = countryCodes[countryName]?.isoA2 ?? "CA";
    return Provider(
      icon: speciality.icon,
      patientUuid: json['patient_uuid'] ?? uuid.toString(),
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

  void save() {
    DatabaseManager().saveProvider(this);
  }

  // Helper to convert back to Map for your SQLite insert methods
  Map<String, dynamic> toMap() {
    return {
      "provider_uuid": id,
      "patient_uuid": patientUuid,
      "first_name": firstName,
      "last_name": lastName,
      "office_email": email,
      "gender": gender,
      "position": position,
      "is_specialist": isSpecialist == null
          ? 0
          : isSpecialist!
          ? 1
          : 0,
      "pager": pager,
      "office_phone": phone,
    };
  }
}
