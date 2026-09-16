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
    // Omitted outright when it was never recorded, rather than sent as the value
    // Patient.fromJson infers. That inference is "A+" (both columns are nullable and
    // index 0 of each enum), which on a profile screen is a cosmetic default and on
    // this payload is a specific, wrong, clinically actionable claim made to a
    // responder. Absent means unknown; it must never mean "probably A+".
    final bool hasBloodType = await DatabaseManager().isBloodTypeRecorded(
      patient.patientUuid,
    );

    return {
      "name": "${patient.firstName} ${patient.lastName}",
      "phn": patient.phn,
      if (hasBloodType) "bloodType": patient.bloodType.label,
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

  // The wrist variant of the payload above, and deliberately not the same thing.
  //
  // A watch face gives a QR roughly 14mm of glass. The full JSON payload — braces,
  // quotes, and keys like "emergencyContact" — pushes the code past 60 modules a side,
  // which puts each module near 0.2mm: below what a phone camera reliably resolves at
  // arm's length, in bad light, held by someone else's shaking hands. That is the only
  // condition this ever has to work in, so the fix is a shorter payload, not a bigger
  // code.
  //
  // Plain labelled text rather than JSON, for two reasons: it is materially shorter,
  // and most generic QR readers display raw text — a responder scanning this with
  // whatever app is on their phone sees legible lines, not a wall of punctuation.
  //
  // Scope per product decision: name, blood type, allergies, conditions. No phone
  // numbers, no PHN, no family doctor — a responder's first thirty seconds don't need
  // them, and every character spent is glass taken away from the modules.
  static Future<String> buildWatchEmergencyText(Patient patient) async {
    final List<String> allergies = await DatabaseManager().getAllergyNames(patient.patientUuid);
    final List<String> conditions = await DatabaseManager().getActiveConditionNames(patient.patientUuid);
    // Never asserted unless actually recorded — see DatabaseManager.isBloodTypeRecorded.
    final bool hasBloodType = await DatabaseManager().isBloodTypeRecorded(patient.patientUuid);

    // Truncated rather than allowed to grow without bound: someone with a dozen
    // allergies would otherwise silently push the code back past the scannable size,
    // which fails closed and shows nothing rather than showing most of it.
    String list(List<String> items) {
      const int cap = 4;
      if (items.length <= cap) return items.join(', ');
      return '${items.take(cap).join(', ')} +${items.length - cap} more';
    }

    return [
      '${patient.firstName} ${patient.lastName}'.trim(),
      if (hasBloodType) 'Blood: ${patient.bloodType.label}',
      if (allergies.isNotEmpty) 'Allergies: ${list(allergies)}',
      if (conditions.isNotEmpty) 'Conditions: ${list(conditions)}',
    ].join('\n');
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
