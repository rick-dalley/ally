import 'package:flutter/material.dart';
import 'package:triage/classes/staff.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffIdCard extends StatelessWidget {
  final String photoPath;
  final String name;
  final String position;
  final String department;
  final String staffId;
  final String hireDate;
  final String phone;
  final String email;
  final String? pager;
  final IconData icon;
  final DepartmentColors departmentColor;
  final int index;

  const StaffIdCard({
    super.key,
    required this.photoPath,
    required this.name,
    required this.position,
    required this.department,
    required this.staffId,
    required this.hireDate,
    required this.phone,
    required this.email,
    this.pager,
    required this.icon,
    required this.departmentColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
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
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              height: 40.0,
              width: double.infinity,
              color: departmentColorList[departmentColor],
              alignment: Alignment.center, // This centers the Row within the Container
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // This centers the children inside the Row
                children: [
                  Text(
                    "University Hospital - $department",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Icon(icon, color: Colors.white),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(photos[index % 16]!, width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  // Right Side: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(position, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text("ID: ${staffId.toUpperCase().substring(0, 8)}"),
                        Text("Hired: $hireDate"),
                        const SizedBox(height: 8),
                        // Placeholder for Barcode/QR
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              color: Colors.black12, // Replace with your QR/Barcode widget
                            ),
                            Container(
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final Uri emailLaunchUri = Uri(
                                        scheme: 'mailto',
                                        path: email,
                                        query: 'subject=Hello&body=Regarding your inquiry...', // Optional
                                      );

                                      if (await canLaunchUrl(emailLaunchUri)) {
                                        await launchUrl(emailLaunchUri);
                                      } else {
                                        // Handle the error (e.g., show a snackbar saying no email app is configured)
                                      }
                                    },
                                    child: Text(
                                      email,
                                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                  Text("Ph: $phone"),
                                  if (pager != null || pager!.isNotEmpty) Text("Pg: $pager"),
                                ],
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
