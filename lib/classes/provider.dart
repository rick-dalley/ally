import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:triage/classes/phone.dart';
import 'package:triage/classes/specialities.dart';
import 'package:triage/classes/uuid.dart';

import 'address.dart';
import 'country_codes.dart';
import 'database_manager.dart';
import 'contact.dart';

class Provider {
  final String id;
  Uint8List? image;
  String patientUuid;
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
  Contact? contact;
  Address? address;
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
    this.color,
    this.department,
    this.icon,
    this.address,
    this.contact,
  });
  String getEmail(EmailTypes emailType) {
    String email = '';
    if (contact != null) {
      if (contact!.emails.isNotEmpty) {
        email = contact!.emails[emailType] ?? '';
      }
    }
    return email;
  }

  Phone? getAvailablePhone({required PhoneTypes preferred}) {
    Phone? phone;
    if (contact != null) {
      phone = contact!.getAvailablePhone(preferred: PhoneTypes.office);
    }
    return phone;
  }

  String getPhone({required PhoneTypes phoneType}) {
    String phone = '';
    if (contact != null) {
      contact!.getPhoneNumber(phoneType: phoneType);
    }
    return phone;
  }

  String get fullName => '$firstName $lastName';

  factory Provider.fromJson(Map<String, dynamic> json) {
    String countryName = json["country"] ?? "Canada";
    String iso = toCountryCode[countryName]?.isoA2 ?? "CA";
    Address addressRaw = Address(
      city: json["city"] ?? "",
      street: json["street"] ?? "",
      country: json["country"] ?? "",
      code: json["code"] ?? "",
      provOrState: json["pr_st"] ?? "",
      countryIso: iso,
    );
    String pagerRaw = json["pager"] ?? "";
    String phoneRaw = json["personal_phone"] ?? "";
    String officeRaw = json['office_phone'] ?? '';
    String firstNameRaw = json["first_name"];
    String lastNameRaw = json["last_name"];
    String fullName = '$firstNameRaw $lastNameRaw';
    String emailRaw = json["personal_email"] ?? "";
    Phone pgr = Phone(number: pagerRaw, phoneType: PhoneTypes.pager, isMain: false);
    Phone cel = Phone(number: phoneRaw, phoneType: PhoneTypes.cell, isMain: false);
    Phone office = Phone(number: officeRaw, phoneType: PhoneTypes.office, isMain: true);
    Map<PhoneTypes, Phone> allPhones = {PhoneTypes.pager: pgr, PhoneTypes.cell: cel, PhoneTypes.office: office};
    Contact contactRaw = Contact(name: fullName, email: emailRaw, phone: office);
    return Provider(
      // image: json['avatar'],
      patientUuid: json['patient_uuid'] ?? uuid.toString(),
      id: json["provider_uuid"],
      firstName: firstNameRaw,
      lastName: lastNameRaw,
      email: emailRaw,
      gender: json["gender"],
      position: json["position"],
      hireDate: DateTime.now().subtract(Duration(days: 365)),
      isSpecialist: (json["is_specialist"] == 1),
      accreditations: json['accreditations'],
      onCall: (json["on_call"] == 1),
      address: addressRaw,
      contact: contactRaw,
      specialities: json['specialities'] ?? '',
    );
  }

  Future<void> save() async {
    firstName ??= '';
    lastName ??= '';
    await DatabaseManager().saveProvider(this);
  }

  Future<void> delete() async {
    await DatabaseManager().deleteProvider(providerUuid: id);
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
      contact = Contact.copy(provider.contact);
      address = Address.copy(provider.address);
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

    String officePhone = '';
    String pagerPhone = '';
    String personalPhone = '';
    String personalEmail = '';
    if (contact != null) {
      officePhone = contact!.getPhoneNumber(phoneType: PhoneTypes.office) ?? '';
      pagerPhone = contact!.getPhoneNumber(phoneType: PhoneTypes.pager) ?? '';
      personalPhone = contact!.getPhoneNumber(phoneType: PhoneTypes.cell) ?? '';
      personalEmail = contact!.getEmail(emailType: EmailTypes.personal) ?? '';
    }
    return {
      "avatar": image,
      "provider_uuid": id,
      "patient_uuid": patientUuid,
      "first_name": firstName,
      "last_name": lastName,
      "personal_email": personalEmail,
      "personal_phone": personalPhone,
      "office_email": email,
      "office_phone": officePhone,
      "gender": gender,
      "position": position,
      "is_specialist": isSpecialist == null
          ? 0
          : isSpecialist!
          ? 1
          : 0,
      "pager": pagerPhone,
      "specializations": specialities,
      "accreditations": accreditations,
      // "purpose":purpose,
      // "started_seeing":startedSeeing,
      // "stopped_seeing": stoppedSeeing,
      "street": address?.street,
      "code": address?.code,
      "city": address?.city,
      "country": address?.country,
      "pr_st": address?.provOrState,
      "facility": address?.locationName,
    };
  }
}
