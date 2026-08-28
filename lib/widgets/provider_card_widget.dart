import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/colors/medical_category_colors.dart';
import 'package:ally/classes/phone.dart';
import 'package:ally/classes/provider.dart';
import 'package:ally/widgets/avatar_picker.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/uuid.dart';
import 'appointment_chip.dart';
import 'book_appointment_sheet.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';

class ProviderCard extends StatefulWidget {
  final Patient user;
  final Provider? provider;
  final int index;
  final Function(Provider provider)? onCardUpdated;
  final Function(Provider provider)? onDeleteCard;
  const ProviderCard({
    super.key,
    required this.provider,
    required this.user,
    required this.index,
    this.onCardUpdated,
    this.onDeleteCard,
  });

  @override
  State<StatefulWidget> createState() => ProviderCardState();
}

class ProviderCardState extends State<ProviderCard> {
  late Provider provider = widget.provider ?? Provider(id: uuid.toString(), patientUuid: widget.user.patientUuid);
  Appointment? _appointment;
  bool _loadingAppointment = true;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    final rows = await DatabaseManager().getAppointmentsForProvider(widget.user.patientUuid, provider.id);
    if (!mounted) return;
    setState(() {
      _appointment = _pickRelevant(rows);
      _loadingAppointment = false;
    });
  }

  // The one appointment worth showing as a chip: the soonest still-scheduled upcoming
  // one, or — if nothing's upcoming — the most recent past one, matching the chip's
  // own "history" styling for that case.
  Appointment? _pickRelevant(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    final DateTime now = DateTime.now();
    final List<Appointment> appointments = rows.map((row) => Appointment.fromRow(row, provider)).toList();

    final List<Appointment> upcoming =
        appointments.where((a) => a.when.isAfter(now) && a.status == 'scheduled').toList()
          ..sort((a, b) => a.when.compareTo(b.when));
    if (upcoming.isNotEmpty) return upcoming.first;

    final List<Appointment> past = appointments.where((a) => !a.when.isAfter(now)).toList()
      ..sort((a, b) => b.when.compareTo(a.when));
    return past.isNotEmpty ? past.first : null;
  }

  // Reloads unconditionally once the sheet closes, regardless of how it closed —
  // dismissing by tapping the background pops with a null result, not true, so gating
  // the reload on the return value meant a background-dismiss after a successful save
  // would leave the new appointment invisible until the whole screen was reopened.
  Future<void> _openBooking() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => BookAppointmentSheet(patientUuid: widget.user.patientUuid, provider: provider),
    );
    await _loadAppointment();
  }

  Future<void> openMap(String address) async {
    // Encode the address for a URL
    final String encodedAddress = Uri.encodeComponent(address);
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  void handleAvatarPicked(Uint8List? image) {
    setState(() {
      provider.image = image;
      provider.save();
      if (widget.onCardUpdated != null) {
        widget.onCardUpdated!(provider);
      }
    });
  }

  void handleDelete() {
    if (widget.onDeleteCard != null) {
      widget.onDeleteCard!(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    String pager = provider.getPhone(phoneType: PhoneTypes.pager);
    String qualifications = "${provider.specialities ?? 'General'} - ${provider.department ?? 'Family Medicine'}";
    String name = "${provider.firstName} ${provider.lastName}";
    // Same body-system palette as Conditions/Allergies — a cardiologist's card and a
    // cardiovascular condition sharing a color is a real, meaningful association, not
    // a collision, unlike reusing a Carbon semantic color would be.
    final MedicalCategory category = categoryForSpecialty(provider.specialities ?? provider.position);
    Phone? phone = provider.getAvailablePhone(preferred: PhoneTypes.office);
    String phoneInformation = '';
    if (phone != null) {
      phoneInformation = 'Ph:${phone.number} (${phone.phoneType.label})';
    }
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              height: 48.0,
              width: double.infinity,
              color: category.color,
              alignment: Alignment.center, // This centers the Row within the Container
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // This centers the children inside the Row
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(category.iconData, color: category.textColor, size: 24),
                  Expanded(
                    child: Text(
                      qualifications,
                      style: CarbonTheme.carbonLabelOnPrimary?.copyWith(color: category.textColor),
                    ),
                  ),
                  CarbonIconButton(onPressed: handleDelete, icon: Symbols.close),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Photo
                  Column(
                    mainAxisSize: MainAxisSize.min, // Constrains the column to the size of its children
                    children: [
                      Container(
                        width: 184,
                        height: 184,
                        decoration: BoxDecoration(
                          border: Border.all(color: carbonColorBorderSubtle03, width: 1.0),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: AvatarPicker(onPicked: handleAvatarPicked, rawImage: provider.image),
                      ),
                      const SizedBox(height: 8), // Add some breathing room
                      // Use a fixed size or just wrap the content
                      SizedBox(
                        width: 184, // Match the width of the image
                        child: _loadingAppointment
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_appointment != null)
                                    AppointmentChip(
                                      appointment: _appointment!,
                                      patientUuid: widget.user.patientUuid,
                                      provider: provider,
                                      onChanged: _loadAppointment,
                                    ),
                                  const SizedBox(height: 4),
                                  CarbonCompactButton(
                                    icon: Symbols.event,
                                    label: _appointment != null ? "Book Another" : "Book Appointment",
                                    style: CarbonButtonStyle.ghost,
                                    onTap: _openBooking,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Right Side: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(provider.position ?? '', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: provider.email,
                              query: 'subject=Hello&body=Regarding your inquiry...', // Optional
                            );

                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            } else {
                              // Handle the error (e.g., show a snackbar saying no email app is configured)
                            }
                          },
                          child: Text(
                            provider.email ?? '',
                            style: TextStyle(color: carbonColorBorderInteractive, decoration: TextDecoration.underline),
                          ),
                        ),
                        Text(phoneInformation, style: CarbonTheme.carbonLabelTextStyle),
                        if (pager.isNotEmpty) Text("Pg: $pager"),
                        const SizedBox(height: 8),
                        // Placeholder for Barcode/QR
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (provider.address != null) {
                                    String? fullAddress = provider.address!.full;
                                    openMap(fullAddress);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Address", style: const TextStyle(color: Colors.grey)),
                                      Text("${provider.address?.street}"),
                                      Text("${provider.address?.city}"),
                                      Text("${provider.address?.provOrState}"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
