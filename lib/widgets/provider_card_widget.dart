import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/classes/phone.dart';
import 'package:triage/classes/provider.dart';
import 'package:triage/widgets/avatar_picker.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../classes/patient.dart';
import '../classes/uuid.dart';
import 'appointment_chip.dart';

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
              color: carbonColorButtonPrimary, //provider.color?.color,
              alignment: Alignment.center, // This centers the Row within the Container
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // This centers the children inside the Row
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(Symbols.medication, color: carbonColorButtonPrimary, size: 24),
                  Expanded(child: Text(qualifications, style: CarbonTheme.carbonLabelOnPrimary)),
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
                        child: AppointmentChip(),
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
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ),
                        Text(phoneInformation, style: CarbonTheme.carbonLabelTextStyle),
                        if (pager.isNotEmpty) Text("Pg: $pager"),
                        const SizedBox(height: 8),
                        // Placeholder for Barcode/QR
                        Row(
                          children: [
                            InkWell(
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
