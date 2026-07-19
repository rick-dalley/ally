import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/staff.dart';
import '../app_theme.dart';

class Address {
  final String? locationName;
  final String street;
  final String city;
  final String provinceOrState;
  final String code;
  final String country;
  const Address({
    required this.city,
    required this.street,
    required this.country,
    required this.code,
    required this.provinceOrState,
    this.locationName,
  });
  factory Address.fromMap(Map<String, dynamic> item) {
    String streetRaw = item['street'];
    String cityRaw = item['city'];
    String provinceOrStateRaw = item['pr_st'];
    String codeRaw = item['code'];
    String countryRaw = item['country'];
    return Address(
      city: cityRaw,
      street: streetRaw,
      country: countryRaw,
      code: codeRaw,
      provinceOrState: provinceOrStateRaw,
    );
  }
  String get full {
    return '$street, $city, $provinceOrState, $country, $code';
  }

  String get fullFormatted {
    return '$street,\n $city, $provinceOrState,\n $country,\n $code';
  }
}

enum PhoneTypes { cell, land, fax, other }

class Social {
  final String name;
  final String uri;
  final IconData? icon;
  final String? iconUri;
  const Social({required this.name, required this.uri, this.icon, this.iconUri});
}

class Phone {
  final String number;
  final PhoneTypes phoneType;
  final bool isMain;
  const Phone({required this.number, required this.phoneType, required this.isMain});
}

class Who {
  final String first;
  final String last;
  final String? email;
  List<Phone>? phone = [];
  final String? url;
  List<Social>? social = [];

  Who({required this.first, required this.last, this.email, required this.phone, this.url, required this.social});
}

class Appointment {
  final DateTime when;
  final Who? who;
  final Address? where;
  final String? why;

  const Appointment({required this.when, this.who, this.where, this.why});
}

class AppointmentChip extends StatefulWidget {
  final Appointment? appointment;
  final StaffMember? staffMember;

  const AppointmentChip({super.key, this.appointment, this.staffMember});

  @override
  State<StatefulWidget> createState() => AppointmentChipState();
}

class AppointmentChipState extends State<AppointmentChip> {
  @override
  Widget build(BuildContext context) {
    Who who;
    Appointment? appointment = widget.appointment;
    if (widget.appointment == null) {
      final staffMember = widget.staffMember;
      if (staffMember != null) {
        who = Who(
          first: staffMember.firstName,
          last: staffMember.lastName,
          phone: [Phone(number: staffMember.phone, isMain: true, phoneType: PhoneTypes.land)],
          social: [],
        );
      } else {
        who = Who(first: "", last: "", phone: null, social: null);
      }
      appointment = Appointment(when: DateTime.now(), who: who, where: null, why: "");
    }
    bool? isPast = appointment?.when.isBefore(DateTime.now()) ?? false;
    return ActionChip(
      avatar: Icon(isPast ? Symbols.history : Symbols.calendar_today, size: 16),
      label: Text(DateFormat('MMM d, h:mm a').format(appointment!.when)),
      onPressed: () => _showAppointmentDetails(appointment!),
      backgroundColor: isPast ? Colors.amber.shade50 : AppColors.foamGreen.withValues(alpha: 0.1),
      side: BorderSide(color: isPast ? Colors.amber : AppColors.foamGreen),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {}
}
