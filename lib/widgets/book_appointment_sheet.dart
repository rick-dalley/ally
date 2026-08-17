import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../classes/appointment_reason.dart';
import '../classes/body_markers.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/phone.dart';
import '../classes/provider.dart';
import '../classes/reminder_registry.dart';
import 'appointment_chip.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_checkbox.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

enum _BookingChannel { none, phone, email, text }

// Booking here always means the same two things happen together: a local
// appointment record is saved (so it's Remindable and shows as a chip on the
// caregiver card), and the chosen channel to actually reach the office opens right
// after — there's no scheduling-system integration, so the channel *is* the booking
// action, same honesty as SeekCareSheet. Also doubles as the edit flow — pass an
// `existing` appointment to pre-fill everything and update that row instead of
// inserting a new one, since the two forms need identical fields (when, reason,
// symptoms to discuss, notes).
class BookAppointmentSheet extends StatefulWidget {
  final String patientUuid;
  final Provider provider;
  final Appointment? existing;

  const BookAppointmentSheet({super.key, required this.patientUuid, required this.provider, this.existing});

  @override
  State<BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<BookAppointmentSheet> {
  DateTime? _when;
  final Set<AppointmentReasonPreset> _presets = {};
  final TextEditingController _notesController = TextEditingController();
  String? _error;
  bool _booking = false;

  List<BodyMarker> _activeSymptoms = [];
  final Set<int> _selectedSymptomIds = {};
  bool _loadingSymptoms = true;

  Phone? get _phone => widget.provider.getAvailablePhone(preferred: PhoneTypes.office);
  bool get _hasEmail => widget.provider.email != null && widget.provider.email!.isNotEmpty;
  bool get _hasPhone => _phone != null && _phone!.number.isNotEmpty;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Appointment? existing = widget.existing;
    if (existing != null) {
      _when = existing.when;
      _notesController.text = existing.notes ?? '';
      // Reason is stored as a joined string (e.g. "Regular Checkup, Follow-up") —
      // reconstruct which presets were chosen by matching labels back. A reason that
      // doesn't match any known preset (free text, or the "Appointment" fallback used
      // when nothing was checked) just leaves every preset unchecked, which is fine.
      final Set<String> reasonParts = (existing.why ?? '').split(', ').toSet();
      for (final preset in AppointmentReasonPreset.values) {
        if (reasonParts.contains(preset.label)) _presets.add(preset);
      }
    }
    _loadActiveSymptoms();
  }

  Future<void> _loadActiveSymptoms() async {
    final rows = await DatabaseManager().getMarkersForPatient(widget.patientUuid);
    if (!mounted) return;
    setState(() {
      _activeSymptoms = rows.map((row) => BodyMarker.fromRow(row)).where((marker) => !marker.resolved).toList();
      _loadingSymptoms = false;
    });
  }

  Future<void> _pickWhen() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _error = null;
    });
  }

  String get _combinedReason {
    final List<String> parts = [
      for (final preset in AppointmentReasonPreset.values)
        if (_presets.contains(preset)) preset.label,
    ];
    return parts.join(', ');
  }

  // Folds any active symptoms the patient chose to bring up directly into the saved
  // notes — not just a transient email body, so it's part of the actual appointment
  // record from the moment it's booked.
  String? get _combinedNotes {
    final String typed = _notesController.text.trim();
    final List<BodyMarker> chosen = _activeSymptoms.where((m) => _selectedSymptomIds.contains(m.id)).toList();
    if (chosen.isEmpty) return typed.isEmpty ? null : typed;

    final StringBuffer buffer = StringBuffer();
    if (typed.isNotEmpty) {
      buffer.writeln(typed);
      buffer.writeln();
    }
    buffer.writeln("Symptoms to discuss:");
    for (final marker in chosen) {
      final String severity = marker.severity?.label ?? 'unspecified severity';
      final String frequency = marker.frequency?.label ?? 'unspecified frequency';
      buffer.writeln("- ${marker.name}: $severity, $frequency");
    }
    return buffer.toString().trim();
  }

  Future<void> _book(_BookingChannel channel) async {
    final DateTime? when = _when;
    if (when == null) {
      setState(() => _error = "Pick a date and time first.");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _booking = true);
    final String reason = _combinedReason.isEmpty ? "Appointment" : _combinedReason;
    final String? notes = _combinedNotes;

    // A save must never fail silently — surface the real exception on screen instead
    // of leaving the sheet just sitting there with no explanation.
    try {
      if (_isEditing) {
        await DatabaseManager().updateAppointmentDetails(
          widget.existing!.id,
          scheduledFor: when,
          reason: reason,
          notes: notes,
        );
      } else {
        await DatabaseManager().insertAppointment(
          patientUuid: widget.patientUuid,
          providerUuid: widget.provider.id,
          scheduledFor: when,
          reason: reason,
          notes: notes,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[BookAppointmentSheet] save failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _booking = false;
          _error = 'Save failed: $error';
        });
      }
      return;
    }

    // Pop *before* refreshing reminders, not after. ReminderRegistry.refresh() calls
    // notifyListeners(), which HomeScreen listens to in order to auto-open its own
    // ReminderSheet the moment anything's due — on the same Navigator this sheet is
    // on, since ProviderRosterScreen is one of HomeScreen's own IndexedStack tabs, not
    // a separately pushed route. Navigator.pop() always pops whatever is currently on
    // top of the stack, not "this sheet specifically" — if the auto-popup sheet had
    // already been pushed by the time we popped, we'd end up popping *that* instead of
    // ourselves, leaving this sheet stuck on screen. This is why it looked flaky:
    // it only broke when something happened to be due at that exact moment.
    if (mounted) Navigator.pop(context, true);

    // Everything from here on is best-effort cleanup after our own sheet is already
    // gone — no UI left on this widget to report failures to, so just log them.
    try {
      await ReminderRegistry.instance.refresh();
      switch (channel) {
        case _BookingChannel.none:
          break; // just saving — no channel to open
        case _BookingChannel.phone:
          final Uri uri = Uri(scheme: 'tel', path: _phone!.number);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        case _BookingChannel.email:
          final Uri uri = Uri(
            scheme: 'mailto',
            path: widget.provider.email,
            queryParameters: {
              'subject': _isEditing
                  ? 'Appointment change — ${widget.provider.fullName}'
                  : 'Appointment request — ${widget.provider.fullName}',
              'body':
                  "Hi Dr. ${widget.provider.lastName},\n\n"
                  "${_isEditing ? "I'd like to update my appointment to" : "I'd like to book an appointment for"} ${_formatWhen(when)}.\n"
                  "Reason: $reason${notes != null ? '\n\nNotes: $notes' : ''}",
            },
          );
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        case _BookingChannel.text:
          final Uri uri = Uri(
            scheme: 'sms',
            path: _phone!.number,
            queryParameters: {
              'body':
                  "Hi, ${_isEditing ? "I'd like to update my appointment to" : "I'd like to book an appointment for"} ${_formatWhen(when)}. Reason: $reason",
            },
          );
          if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (error, stackTrace) {
      debugPrint('[BookAppointmentSheet] post-pop cleanup failed: $error\n$stackTrace');
    }
  }

  String _formatWhen(DateTime when) {
    final String hh = when.hour.toString().padLeft(2, '0');
    final String mm = when.minute.toString().padLeft(2, '0');
    return '${when.month}/${when.day}/${when.year} at $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? "Edit Appointment" : "Book an Appointment", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 4),
            Text("with ${widget.provider.fullName}", style: CarbonTheme.carbonHintTextStyle),
            const SizedBox(height: 20),
            CarbonCompactButton(
              icon: Symbols.event,
              label: _when == null ? "Pick a Date & Time" : _formatWhen(_when!),
              style: CarbonButtonStyle.secondary,
              onTap: _pickWhen,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: CarbonTheme.dangerTextStyle),
            ],
            const SizedBox(height: 20),
            Text("Why is this appointment being booked?", style: CarbonTheme.carbonLabelTextStyle),
            for (final preset in AppointmentReasonPreset.values)
              CarbonCheckboxListTile(
                value: _presets.contains(preset),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _presets.add(preset);
                    } else {
                      _presets.remove(preset);
                    }
                  });
                },
                title: Text(preset.label),
              ),
            if (!_loadingSymptoms && _activeSymptoms.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text("Bring up an active symptom?", style: CarbonTheme.carbonLabelTextStyle),
              Text(
                "Adds the details to your appointment notes.",
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              for (final marker in _activeSymptoms)
                CarbonCheckboxListTile(
                  value: _selectedSymptomIds.contains(marker.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedSymptomIds.add(marker.id!);
                      } else {
                        _selectedSymptomIds.remove(marker.id);
                      }
                    });
                  },
                  title: Text("${marker.name}${marker.severity != null ? ' (${marker.severity!.label})' : ''}"),
                ),
            ],
            const SizedBox(height: 12),
            CarbonTextInput(
              label: "Additional notes (optional)",
              helperText: "Anything specific to bring up",
              controller: _notesController,
              maxLines: 3,
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: _isEditing ? "Save Changes" : "Save Appointment",
              style: CarbonButtonStyle.primary,
              onTap: _booking ? () {} : () => _book(_BookingChannel.none),
            ),
            if (_hasPhone || _hasEmail) ...[
              const SizedBox(height: 20),
              Text(
                _isEditing ? "Or, save and let the office know:" : "Or, save and reach out now:",
                style: CarbonTheme.carbonLabelTextStyle,
              ),
              const SizedBox(height: 8),
              if (_hasPhone) ...[
                CarbonCompactButton(
                  icon: Symbols.call,
                  label: "Call the Office",
                  style: CarbonButtonStyle.secondary,
                  onTap: _booking ? () {} : () => _book(_BookingChannel.phone),
                ),
                const SizedBox(height: 8),
              ],
              if (_hasEmail) ...[
                CarbonCompactButton(
                  icon: Symbols.mail,
                  label: "Email the Office",
                  style: CarbonButtonStyle.secondary,
                  onTap: _booking ? () {} : () => _book(_BookingChannel.email),
                ),
                const SizedBox(height: 8),
              ],
              if (_hasPhone)
                CarbonCompactButton(
                  icon: Symbols.sms,
                  label: "Text the Office",
                  style: CarbonButtonStyle.secondary,
                  onTap: _booking ? () {} : () => _book(_BookingChannel.text),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
