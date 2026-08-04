import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/provider.dart';
import '../app_theme.dart';
import '../classes/address.dart';
import '../classes/contact.dart';
import '../classes/phone.dart';

class Appointment {
  final DateTime when;
  final Contact? who;
  final Address? where;
  final String? why;

  const Appointment({required this.when, this.who, this.where, this.why});
}

class AppointmentChip extends StatefulWidget {
  final Appointment? appointment;
  final Provider? provider;

  const AppointmentChip({super.key, this.appointment, this.provider});

  @override
  State<StatefulWidget> createState() => AppointmentChipState();
}

class AppointmentChipState extends State<AppointmentChip> {
  late Provider? provider = widget.provider;
  @override
  Widget build(BuildContext context) {
    Contact who;
    Appointment? appointment = widget.appointment;
    if (widget.appointment == null) {
      final provider = this.provider;
      if (provider != null) {
        who = Contact(
          name: provider.fullName,
          email: provider.getEmail(EmailTypes.office),
          phone: Phone.fromPhoneNumber(provider.getPhone(phoneType: PhoneTypes.office)),
        );
      } else {
        Phone phone = Phone(number: '', phoneType: PhoneTypes.cell, isMain: false);
        who = Contact(name: "", phone: phone, email: '');
      }
      appointment = Appointment(when: DateTime.now(), who: who, where: null, why: "");
    }
    bool? isPast = appointment?.when.isBefore(DateTime.now()) ?? false;
    return ActionChip(
      avatar: Icon(isPast ? Symbols.history : Symbols.calendar_today, size: 16),
      label: Text(DateFormat('MMM d, h:mm a').format(appointment!.when)),
      onPressed: () => _showAppointmentDetails(appointment!),
      backgroundColor: isPast ? Colors.amber.shade50 : AppTheme.primaryColor.withValues(alpha: 0.1),
      side: BorderSide(color: isPast ? Colors.amber : AppTheme.primaryColor),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {}
}
