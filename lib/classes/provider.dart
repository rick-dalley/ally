import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ally/classes/phone.dart';
import 'package:ally/classes/specialities.dart';
import 'package:ally/classes/uuid.dart';

import 'address.dart';
import 'cancellation_policy.dart';
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
  String? website;
  String? gender;
  String? position;
  DateTime? hireDate;
  bool? isSpecialist;
  String? specialities;
  String? accreditations;
  bool? onCall;
  String? department;
  String? purpose; // shown in the Add Caregiver form as "Notes" — maps to the existing purpose column
  CancellationBillingPolicy? cancellationPolicy;
  int? cancellationNoticeHours;
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
    this.website,
    this.gender,
    this.position,
    this.hireDate,
    this.isSpecialist,
    this.onCall,
    this.color,
    this.department,
    this.purpose,
    this.cancellationPolicy,
    this.cancellationNoticeHours,
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
      phone = contact!.getAvailablePhone(preferred: preferred);
    }
    return phone;
  }

  String getPhone({required PhoneTypes phoneType}) {
    String phone = '';
    if (contact != null) {
      phone = contact!.getPhoneNumber(phoneType: phoneType) ?? '';
    }
    return phone;
  }

  // Keeps the Contact-construction details (it starts null on a freshly-created
  // Provider, and phone numbers live in its `phones` map, not the field the
  // constructor requires) out of any widget that just wants to set a phone number.
  void setPhone(PhoneTypes type, String number) {
    contact ??= Contact(
      name: fullName,
      email: email ?? '',
      phone: Phone(number: number, phoneType: type, isMain: type == PhoneTypes.office),
    );
    contact!.addPhone(type, Phone(number: number, phoneType: type, isMain: type == PhoneTypes.office));
  }

  // Preserves whatever other address fields are already set (city/state/etc. aren't
  // collected by every form that edits street) rather than clobbering them, since
  // Address is immutable and there's no partial-update on it.
  void setStreet(String street) {
    final Address current =
        address ?? const Address(city: '', street: '', country: '', code: '', provOrState: '', countryIso: 'US');
    address = Address(
      city: current.city,
      street: street,
      country: current.country,
      code: current.code,
      provOrState: current.provOrState,
      countryIso: current.countryIso,
      locationName: current.locationName,
    );
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
    Contact contactRaw = Contact(name: fullName, email: emailRaw, phone: office)..phones = allPhones;
    return Provider(
      image: json['avatar'] as Uint8List?,
      patientUuid: json['patient_uuid'] ?? uuid.toString(),
      id: json["provider_uuid"],
      firstName: firstNameRaw,
      lastName: lastNameRaw,
      email: emailRaw,
      website: json['website'] as String?,
      gender: json["gender"],
      position: json["position"],
      hireDate: DateTime.now().subtract(Duration(days: 365)),
      isSpecialist: (json["is_specialist"] == 1),
      accreditations: json['accreditations'],
      onCall: (json["on_call"] == 1),
      address: addressRaw,
      contact: contactRaw,
      specialities: json['specialities'] ?? '',
      purpose: json['purpose'] as String?,
      cancellationPolicy: json['cancellation_policy'] != null
          ? CancellationBillingPolicy.values.byName(json['cancellation_policy'] as String)
          : null,
      cancellationNoticeHours: json['cancellation_notice_hours'] as int?,
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
      website = provider.website;
      gender = provider.gender;
      position = provider.position;
      hireDate = provider.hireDate;
      isSpecialist = provider.isSpecialist;
      specialities = provider.specialities;
      accreditations = provider.accreditations;
      onCall = provider.onCall;
      department = provider.department;
      purpose = provider.purpose;
      cancellationPolicy = provider.cancellationPolicy;
      cancellationNoticeHours = provider.cancellationNoticeHours;
      contact = Contact.copy(provider.contact);
      address = Address.copy(provider.address);
      color = provider.color;
      icon = provider.icon;
    }
  }

  Future<void> refresh() async {
    final List<Map<String, dynamic>> rows = await DatabaseManager().getProvider(id: id);
    if (rows.isNotEmpty) copy(Provider.fromJson(rows.first));
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
      "website": website,
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
      "purpose": purpose,
      "cancellation_policy": cancellationPolicy?.name,
      "cancellation_notice_hours": cancellationNoticeHours,
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
