import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/provider.dart';
import '../app_theme.dart';
import '../classes/address.dart';
import '../classes/cancellation_policy.dart';
import '../classes/contact.dart';
import '../classes/phone.dart';
import 'appointment_details_sheet.dart';

class Appointment {
  final String id;
  final DateTime when;
  final Contact? who;
  final Address? where;
  final String? why;
  final String? notes;
  final String status;
  // Carried from the provider at load time (not stored on the appointment row itself)
  // so the details sheet can warn about a late cancellation without a second lookup.
  final CancellationBillingPolicy? cancellationPolicy;
  final int? cancellationNoticeHours;

  const Appointment({
    required this.id,
    required this.when,
    this.who,
    this.where,
    this.why,
    this.notes,
    this.status = 'scheduled',
    this.cancellationPolicy,
    this.cancellationNoticeHours,
  });

  factory Appointment.fromRow(Map<String, dynamic> row, Provider provider) {
    final bool hasLocation = (row['location_name'] as String?)?.isNotEmpty == true || (row['street'] as String?)?.isNotEmpty == true;
    return Appointment(
      id: row['id'] as String,
      when: DateTime.parse(row['scheduled_for'] as String),
      who: Contact(
        name: provider.fullName,
        email: provider.email ?? '',
        phone: provider.getAvailablePhone(preferred: PhoneTypes.office) ?? Phone(number: '', phoneType: PhoneTypes.office, isMain: true),
      ),
      where: hasLocation
          ? Address(
              locationName: row['location_name'] as String?,
              city: (row['city'] as String?) ?? '',
              street: (row['street'] as String?) ?? '',
              country: (row['country'] as String?) ?? '',
              code: (row['code'] as String?) ?? '',
              provOrState: (row['pr_st'] as String?) ?? '',
              countryIso: '',
            )
          : null,
      why: row['reason'] as String?,
      notes: row['notes'] as String?,
      status: (row['status'] as String?) ?? 'scheduled',
      cancellationPolicy: provider.cancellationPolicy,
      cancellationNoticeHours: provider.cancellationNoticeHours,
    );
  }
}

// Shows the one appointment worth surfacing for a caregiver card — the soonest
// upcoming one, or the most recent past one if nothing's upcoming (ProviderCard picks
// which). No longer falls back to a fake "right now" appointment when there isn't a
// real one — the caller shows a "Book an Appointment" affordance instead in that case.
class AppointmentChip extends StatelessWidget {
  final Appointment appointment;
  final String patientUuid;
  // Called after the details sheet reports a real change (e.g. a cancellation) — lets
  // the caregiver card reload so a cancelled appointment stops showing as the chip.
  final VoidCallback? onChanged;

  const AppointmentChip({super.key, required this.appointment, required this.patientUuid, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool isPast = appointment.when.isBefore(DateTime.now());
    return ActionChip(
      avatar: Icon(isPast ? Symbols.history : Symbols.calendar_today, size: 16),
      label: Text(DateFormat('MMM d, h:mm a').format(appointment.when)),
      onPressed: () async {
        final bool? changed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          builder: (context) => AppointmentDetailsSheet(appointment: appointment, patientUuid: patientUuid),
        );
        if (changed == true) onChanged?.call();
      },
      backgroundColor: isPast ? Colors.amber.shade50 : AppTheme.primaryColor.withValues(alpha: 0.1),
      side: BorderSide(color: isPast ? Colors.amber : AppTheme.primaryColor),
    );
  }
}
