import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';

// The one screen in the app whose actual user is often not the patient — a first
// responder or bystander in a crisis, scanning this with no familiarity with the app.
// Every field in the payload has to be real: this used to hold hardcoded literal
// allergies/conditions regardless of the patient's actual record, which is a genuine
// safety problem for a screen whose entire purpose is emergency medical information.
class EmergencyQRCodeView extends StatelessWidget {
  final Patient householdMember;

  const EmergencyQRCodeView({super.key, required this.householdMember});

  // Public/static so EmergencyLockScreen's wallpaper generator builds the exact same
  // payload as the live in-app view — one source of truth, no risk of the two drifting
  // apart into showing different data for the same patient.
  static Future<Map<String, dynamic>> buildEmergencyPayload(
    Patient patient,
  ) async {
    final List<String> allergies = await DatabaseManager().getAllergyNames(
      patient.patientUuid,
    );
    final List<String> conditions = await DatabaseManager()
        .getActiveConditionNames(patient.patientUuid);

    return {
      "name": "${patient.firstName} ${patient.lastName}",
      "phn": patient.phn,
      "bloodType": patient.bloodType.label,
      "allergies": allergies,
      "conditions": conditions,
      "familyDoctor": {
        "name": patient.familyDoctorName,
        "phone": patient.familyDoctorPhone,
      },
      "emergencyContact": {
        "name": patient.contactName,
        "phone": patient.contactPhone,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    // Sized relative to screen width instead of a fixed 300px — this needs to scan
    // fast, at arm's length, in bad lighting, possibly with someone else's hands
    // holding the phone. Bigger is strictly better here up to the point it no longer
    // fits the screen.
    final double qrSize = (MediaQuery.sizeOf(context).width * 0.85).clamp(
      280.0,
      480.0,
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: buildEmergencyPayload(householdMember),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator(
                  color: AppTheme.onPrimaryColor,
                );
              }
              final String qrPayload = jsonEncode(snapshot.data ?? {});
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Show this to emergency staff",
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.onPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: qrSize,
                    height: qrSize,
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.onPrimaryColor,
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: qrSize - 32,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
