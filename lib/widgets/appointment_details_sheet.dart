import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../classes/body_markers.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/reminder_registry.dart';
import 'appointment_chip.dart';
import 'carbon_button_compact.dart';

// What "when and where" plus "room to explain the concerns being brought forward"
// actually means once an appointment is real: the booked reason/notes, and an option
// to fold in the patient's own recorded symptoms (from the body-map Symptoms screen)
// so the provider gets real dates/severity, not just a vague verbal description.
class AppointmentDetailsSheet extends StatelessWidget {
  final Appointment appointment;
  final String patientUuid;

  const AppointmentDetailsSheet({super.key, required this.appointment, required this.patientUuid});

  Future<void> _emailDetails(BuildContext context) async {
    final rows = await DatabaseManager().getMarkersForPatient(patientUuid);
    final List<BodyMarker> recentMarkers = rows
        .map((row) => BodyMarker.fromRow(row))
        .where((marker) => !marker.resolved)
        .take(5)
        .toList();

    final StringBuffer body = StringBuffer();
    body.writeln("Hi Dr. ${appointment.who?.name ?? ''},");
    body.writeln();
    body.writeln("Ahead of our appointment on ${_formatWhen(appointment.when)}, here's what I'd like to cover:");
    if (appointment.why != null && appointment.why!.isNotEmpty) {
      body.writeln("Reason: ${appointment.why}");
    }
    if (appointment.notes != null && appointment.notes!.isNotEmpty) {
      body.writeln("Notes: ${appointment.notes}");
    }
    if (recentMarkers.isNotEmpty) {
      body.writeln();
      body.writeln("Symptoms I've been tracking:");
      for (final marker in recentMarkers) {
        final String when = DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(marker.recorded * 1000));
        final String severity = marker.severity?.label ?? 'unspecified severity';
        final String frequency = marker.frequency?.label ?? 'unspecified frequency';
        body.writeln("- ${marker.name}: $severity, $frequency (since $when)");
      }
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: appointment.who?.email,
      queryParameters: {'subject': 'Ahead of our appointment on ${_formatWhen(appointment.when)}', 'body': body.toString()},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
    if (context.mounted) Navigator.pop(context);
  }

  String _formatWhen(DateTime when) {
    final String hh = when.hour.toString().padLeft(2, '0');
    final String mm = when.minute.toString().padLeft(2, '0');
    return '${when.month}/${when.day}/${when.year} at $hh:$mm';
  }

  // Warns, doesn't block — the point is just to make sure the patient knows what
  // they're risking before they cancel, not to build a real billing enforcement system.
  Future<void> _confirmAndCancel(BuildContext context) async {
    final Duration timeUntil = appointment.when.difference(DateTime.now());
    final int? noticeHours = appointment.cancellationNoticeHours;
    final bool violatesNotice =
        noticeHours != null && appointment.cancellationPolicy != null && timeUntil < Duration(hours: noticeHours);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                violatesNotice ? "Cancellation Notice" : "Cancel Appointment?",
                style: CarbonTheme.carbonHeadingTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                violatesNotice
                    ? "${appointment.who?.name ?? 'This provider'} requires $noticeHours hours' notice to cancel. "
                          "Cancelling now may result in ${appointment.cancellationPolicy!.label.toLowerCase()}."
                    : "This will cancel your appointment on ${_formatWhen(appointment.when)}.",
                style: CarbonTheme.carbonHintTextStyle,
              ),
              const SizedBox(height: 24),
              CarbonCompactButton(
                icon: Symbols.cancel,
                label: violatesNotice ? "Cancel Anyway" : "Cancel Appointment",
                style: CarbonButtonStyle.danger,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              CarbonCompactButton(
                icon: Symbols.arrow_back,
                label: "Keep Appointment",
                style: CarbonButtonStyle.ghost,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await DatabaseManager().updateAppointmentStatus(appointment.id, 'cancelled');
      // Pop before refreshing reminders, not after — see BookAppointmentSheet._book
      // for the full explanation. refresh()'s notifyListeners() can trigger
      // HomeScreen's own auto-popup ReminderSheet on this same Navigator, and
      // Navigator.pop() always pops whatever's currently on top of the stack.
      if (context.mounted) Navigator.pop(context, 'cancelled');
      await ReminderRegistry.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEmail = appointment.who?.email.isNotEmpty ?? false;
    // Editing or cancelling a past, already-attended, or already-cancelled
    // appointment doesn't mean anything — both actions share the same guard.
    final bool canModify = appointment.status == 'scheduled' && appointment.when.isAfter(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Appointment Details", style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 4),
          Text("with ${appointment.who?.name ?? 'your provider'}", style: CarbonTheme.carbonHintTextStyle),
          const SizedBox(height: 20),
          _detailRow(Symbols.event, _formatWhen(appointment.when)),
          if (appointment.where != null) _detailRow(Symbols.location_on, appointment.where!.full),
          if (appointment.why != null && appointment.why!.isNotEmpty) _detailRow(Symbols.info, appointment.why!),
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            _detailRow(Symbols.notes, appointment.notes!),
          if (appointment.cancellationPolicy != null && appointment.cancellationNoticeHours != null)
            _detailRow(
              Symbols.policy,
              "Cancellation policy: ${appointment.cancellationPolicy!.label}, "
              "${appointment.cancellationNoticeHours} hours' notice required",
            ),
          const SizedBox(height: 24),
          if (hasEmail) ...[
            CarbonCompactButton(
              icon: Symbols.mail,
              label: "Email Details to Provider",
              style: CarbonButtonStyle.primary,
              onTap: () => _emailDetails(context),
            ),
            const SizedBox(height: 8),
          ],
          if (canModify) ...[
            CarbonCompactButton(
              icon: Symbols.edit,
              label: "Edit Appointment",
              style: CarbonButtonStyle.secondary,
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            const SizedBox(height: 8),
            CarbonCompactButton(
              icon: Symbols.cancel,
              label: "Cancel Appointment",
              style: CarbonButtonStyle.secondary,
              onTap: () => _confirmAndCancel(context),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: CarbonTheme.carbonTextStyle)),
        ],
      ),
    );
  }
}
