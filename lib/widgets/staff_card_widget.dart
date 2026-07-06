import 'package:flutter/material.dart';
import 'package:triage/classes/staff.dart';
import 'package:url_launcher/url_launcher.dart';

import 'appointment_chip.dart';

class StaffIdCard extends StatelessWidget {
  final String photoPath;
  final StaffMember? staffMember;
  final int index;

  const StaffIdCard({super.key, required this.photoPath, required this.staffMember, required this.index});
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

  @override
  Widget build(BuildContext context) {
    String pager = staffMember?.pager ?? "";
    String name = "${staffMember?.firstName} ${staffMember?.lastName}";
    Map<DepartmentColors, Color> departmentColorList = {
      DepartmentColors.blue: Colors.blue,
      DepartmentColors.green: Colors.green,
      DepartmentColors.cyan: Colors.cyan,
      DepartmentColors.purple: Colors.purple,
      DepartmentColors.red: Colors.red,
      DepartmentColors.darkPurple: Colors.deepPurple,
      DepartmentColors.orange: Colors.deepOrange,
      DepartmentColors.slateGray: Colors.blueGrey,
      DepartmentColors.brown: Colors.brown,
      DepartmentColors.indigo: Colors.indigo,
      DepartmentColors.pink: Colors.pink,
    };

    Map<int, String> photos = {
      0: "assets/images/faces/dr_face_1.png",
      1: "assets/images/faces/dr_face_2.png",
      2: "assets/images/faces/emerg_face_1.png",
      3: "assets/images/faces/emerg_face_2.png",
      4: "assets/images/faces/nurse_face_1.png",
      5: "assets/images/faces/nurse_face_2.png",
      6: "assets/images/faces/police_face_1.png",
      7: "assets/images/faces/police_face_2.png",
      8: "assets/images/faces/psych_face_1.png",
      9: "assets/images/faces/psych_face_2.png",
      10: "assets/images/faces/psych_nurse_1.png",
      11: "assets/images/faces/psych_nurse_2.png",
      12: "assets/images/faces/prof_face_1.png",
      13: "assets/images/faces/prof_face_2.png",
      14: "assets/images/faces/prof_yng_1.png",
      15: "assets/images/faces/prof_old_1.png",
    };

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: staffMember == null
            ? SizedBox(height: 100)
            : Column(
                children: [
                  Container(
                    height: 48.0,
                    width: double.infinity,
                    color: departmentColorList[staffMember?.color],
                    alignment: Alignment.center, // This centers the Row within the Container
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // This centers the children inside the Row
                      children: [
                        Text(
                          "University Hospital - ${staffMember?.department}",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 16),
                        Icon(staffMember?.icon, color: Colors.white, size: 24),
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
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF525252), width: 1.0),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Image.asset(photos[index % 16]!, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 8), // Add some breathing room
                            // Use a fixed size or just wrap the content
                            SizedBox(
                              width: 120, // Match the width of the image
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
                              Text(staffMember!.position, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final Uri emailLaunchUri = Uri(
                                    scheme: 'mailto',
                                    path: staffMember?.email,
                                    query: 'subject=Hello&body=Regarding your inquiry...', // Optional
                                  );

                                  if (await canLaunchUrl(emailLaunchUri)) {
                                    await launchUrl(emailLaunchUri);
                                  } else {
                                    // Handle the error (e.g., show a snackbar saying no email app is configured)
                                  }
                                },
                                child: Text(
                                  staffMember!.email,
                                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                ),
                              ),
                              Text("Ph: ${staffMember?.phone}"),
                              if (pager.isNotEmpty) Text("Pg: $pager"),
                              const SizedBox(height: 8),
                              // Placeholder for Barcode/QR
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      openMap(staffMember!.address);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8.0),
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Address", style: const TextStyle(color: Colors.grey)),
                                          Text("${staffMember?.street}"),
                                          Text("${staffMember?.city}"),
                                          Text("${staffMember?.provOrState}"),
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
