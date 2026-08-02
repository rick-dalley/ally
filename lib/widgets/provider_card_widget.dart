import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:triage/classes/provider.dart';
import 'package:triage/classes/specialities.dart';
import 'package:triage/widgets/avatar_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../classes/metric_value.dart';
import '../classes/patient.dart';
import 'appointment_chip.dart';

class ProviderCard extends StatefulWidget {
  final Patient user;
  final Provider? provider;
  final int index;
  final Function(String uuid)? onCardUpdated;
  const ProviderCard({super.key, required this.provider, required this.user, required this.index, this.onCardUpdated});

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
        widget.onCardUpdated!(provider.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String pager = provider.pager ?? "";
    String name = "${provider.firstName} ${provider.lastName}";

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
              color: provider.color?.color,
              alignment: Alignment.center, // This centers the Row within the Container
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // This centers the children inside the Row
                children: [
                  Text(
                    "University Hospital - ${provider.department}",
                    style: TextStyle(color: AppTheme.onPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Icon(provider.icon, color: AppTheme.onPrimaryColor, size: 24),
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
                          border: Border.all(color: const Color(0xFF525252), width: 1.0),
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
                        Text("Ph: ${provider.phone}"),
                        if (pager.isNotEmpty) Text("Pg: $pager"),
                        const SizedBox(height: 8),
                        // Placeholder for Barcode/QR
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                openMap(provider.address);
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Address", style: const TextStyle(color: Colors.grey)),
                                    Text("${provider.street}"),
                                    Text("${provider.city}"),
                                    Text("${provider.provOrState}"),
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
