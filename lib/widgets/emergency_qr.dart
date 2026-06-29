import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart';

import '../classes/patient.dart';

class EmergencyQRCodeView extends StatelessWidget {
  final Patient householdMember;
  // This represents your normalized Emergency Passport data

  const EmergencyQRCodeView({super.key, required this.householdMember});

  @override
  Widget build(BuildContext context) {
    // 1. Serialize data to JSON string
    final Map<String, dynamic> emergencyData = {
      "name": "${householdMember.firstName} ${householdMember.lastName}",
      "bloodType": "O+", //householdMember.bloodType,
      "allergies": ["NSAIDS", "Penicillin"], //householdMember.allergies,
      "conditions": ["hypertensive"], //householdMember.conditions,
      "emergencyContact": {"name": householdMember.contactName, "phone": householdMember.contactPhone},
    };
    final String qrPayload = jsonEncode(emergencyData);
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Emergency Passport")),
      body: SafeArea(
        // This ensures the content respects notches and system UI
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Show this to emergency staff", style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 20),
              Container(
                width: 300,
                height: 300,
                color: Colors.white,
                child: QrImageView(data: qrPayload, version: QrVersions.auto, size: 300.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
