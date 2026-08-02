import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/metric_value.dart';
import 'package:triage/classes/specialities.dart';

import 'country_codes.dart';

class Provider {
  final String id;
  String patientUuid;
  Uint8List? image;
  String? firstName;
  String? lastName;
  String? email;
  String? gender;
  String? position;
  DateTime? hireDate;
  bool? isSpecialist;
  String? specialities;
  String? accreditations;
  bool? onCall;
  String? department;
  String? pager;
  String? phone;
  String? street;
  String? code;
  String? city;
  String? provOrState;
  String? country;
  String? countryIso;
  DepartmentColors? color;
  late IconData? icon;

  Provider({
    required this.id,
    required this.patientUuid,
    this.image,
    this.specialities,
    this.accreditations,
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
    String newId = uuid.toString();
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
      id: newId,
      patientUuid: patientUuid,
      firstName: firstName,
      lastName: lastName,
      phone: contact.selectedPhoneNumber,
    );
  }

  factory Provider.fromJson(Map<String, dynamic> json) {
    String countryName = json["country"] ?? "Canada";
    String countryISO = countryCodes[countryName]?.isoA2 ?? "CA";
    return Provider(
      image: json['avatar'],
      patientUuid: json['patient_uuid'] ?? uuid.toString(),
      id: json["provider_uuid"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      email: json["personal_email"] ?? "",
      gender: json["gender"],
      position: json["position"],
      hireDate: DateTime.now().subtract(Duration(days: 365)),
      isSpecialist: (json["is_specialist"] == 1),
      accreditations: json['accreditations'],
      onCall: (json["on_call"] == 1),
      pager: json["pager"] ?? "",
      phone: json["personal_phone"] ?? "",
      street: json["street"] ?? "",
      city: json["city"] ?? "",
      provOrState: json["pr_st"] ?? "",
      code: json["code"] ?? "",
      country: json["country"] ?? "",
      specialities: json['specialities'] ?? '',
      countryIso: countryISO,
    );
  }

  void save() {
    DatabaseManager().saveProvider(this);
  }

  void copy(Provider? provider) {
    if (provider != null) {
      patientUuid = provider.patientUuid;
      image = provider.image;
      firstName = provider.firstName;
      lastName = provider.lastName;
      email = provider.email;
      gender = provider.gender;
      position = provider.position;
      hireDate = provider.hireDate;
      isSpecialist = provider.isSpecialist;
      specialities = provider.specialities;
      accreditations = provider.accreditations;
      onCall = provider.onCall;
      department = provider.department;
      pager = provider.pager;
      phone = provider.phone;
      street = provider.street;
      code = provider.code;
      city = provider.city;
      provOrState = provider.provOrState;
      country = provider.country;
      countryIso = provider.countryIso;
      color = provider.color;
      icon = provider.icon;
    }
  }

  Future<void> refresh() async {
    dynamic result = await DatabaseManager().getProvider(id: id);
    copy(Provider.fromJson(result));
  }

  // Helper to convert back to Map for your SQLite insert methods
  Map<String, dynamic> toMap() {
    // String sql =  '''
    // CREATE TABLE IF NOT EXISTS provider (
    // provider_uuid TEXT PRIMARY KEY NOT NULL,
    // patient_uuid TEXT NOT NULL,
    // first_name TEXT NOT NULL,
    // last_name TEXT NOT NULL,
    // avatar BLOB,
    // gender TEXT,
    // position TEXT,
    // is_specialist INTEGER DEFAULT 0,
    // pager TEXT,
    // city TEXT,
    // street TEXT,
    // pr_st TEXT,
    // code TEXT,
    // country TEXT,
    // accreditations TEXT,
    // specializations TEXT,
    // facility TEXT,
    // office_phone TEXT,
    // office_email TEXT,
    // personal_phone TEXT,
    // personal_email TEXT,
    // started_seeing DATETIME,
    // stopped_seeing DATETIME,
    // purpose TEXT, FOREIGN KEY(patient_uuid) REFERENCES patient(patient_uuid) ON DELETE CASCADE);''';

    return {
      "avatar": image,
      "provider_uuid": id,
      "patient_uuid": patientUuid,
      "first_name": firstName,
      "last_name": lastName,
      // "personal_email":personalEmail,
      "office_email": email,
      "street": street,
      "gender": gender,
      "position": position,
      "is_specialist": isSpecialist == null
          ? 0
          : isSpecialist!
          ? 1
          : 0,
      "pager": pager,
      "specializations": specialities,
      "accreditations": accreditations,
      // "purpose":purpose,
      // "started_seeing":startedSeeing,
      // "stopped_seeing": stoppedSeeing,
      "code": code,
      "city": city,
      "country": country,
      "pr_st": provOrState,
      // "facility":facility,
      // "personal_phone": personalPhone,
      "office_phone": phone,
    };
  }
}
