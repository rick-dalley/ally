import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/carbon_style_button.dart';

import '../app_theme.dart';
import '../widgets/carbon_style_full_button.dart';
import '../widgets/carbon_style_textbox.dart';
import '../widgets/text_scanner.dart';

class AddMedicationScreen extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final VoidCallback onAddMedication;

  const AddMedicationScreen({
    super.key,
    required this.dosageController,
    required this.nameController,
    required this.onAddMedication,
  });

  @override
  State<StatefulWidget> createState() => AddMedicationScreenState();
}

class AddMedicationScreenState extends State<AddMedicationScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Moves with keyboard
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Modal only takes as much space as needed
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Add a medication", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
          ),
          const SizedBox(height: 24),
          CarbonFullButton(
            label: 'SCAN LABEL BAR CODE',
            onTap: () {
              Navigator.pop(context); // Close modal
              _startBarcodeScanner();
            },
            color: AppTheme.deepLogicViolet,
            icon: Symbols.qr_code_2_add,
          ),

          const SizedBox(height: 20),
          const Text("OR ENTER MANUALLY", style: TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 12),

          // OPTION 2: YOUR ORIGINAL FORM FIELDS
          CarbonTextEdit(
            controller: widget.nameController,
            label: "Medication Name",
            helperText: "Enter the name of the medication rather than the brand",
          ),
          CarbonTextEdit(
            controller: widget.dosageController,
            label: "Dosage",
            helperText: "Enter the amount medication usually mg",
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CarbonButton(
                  label: "CANCEL",
                  isSecondary: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: CarbonButton(
                  label: "ADD TO LIST",
                  onPressed: () {
                    widget.onAddMedication; // Your existing function
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _startBarcodeScanner() async {
    // Use a simple full-screen modal or a dedicated camera route
    final String? scannedResult = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BarcodeScannerModal(),
    );

    if (scannedResult != null) {
      // We found something!
      setState(() {
        // For now, let's assume the result is the DIN
        // In the future, this is where you'd trigger your API lookup
        widget.nameController.text = "Loading Med for $scannedResult...";
        widget.dosageController.text = ""; // Placeholder until sync/lookup finishes
      });

      // Auto-trigger your existing lookup logic
      // This matches the background sync you already have in _addMedication
      _lookupAndAdd(scannedResult);
    }
  }

  // A helper to handle the lookup after scanning
  void _lookupAndAdd(String barcodeValue) {
    // Check if it's a known DIN (like your Amlodipine example)
    if (barcodeValue == "02331292") {
      setState(() {
        widget.nameController.text = "Amlodipine";
        widget.dosageController.text = "10 MG Oral Tablet";
      });
    } else {
      // If not in your "local" demo cache, use your existing name field
      // to start the background sync process you've already built
      widget.nameController.text = barcodeValue;
      widget.onAddMedication;
    }
  }
}

class _BarcodeScannerModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            "ALIGN BARCODE",
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Your existing scanner logic, configured for Barcodes
                TextScanner(
                  onTextDetected: (text) {
                    // Search for an 8-digit sequence (DIN) in the OCR
                    final dinRegex = RegExp(r'\b\d{8}\b');
                    final match = dinRegex.firstMatch(text.text);
                    if (match != null) {
                      Navigator.pop(context, match.group(0));
                    }
                  },
                ),
                // Visual "Scope" to help the clinician
                Container(
                  width: 280,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
