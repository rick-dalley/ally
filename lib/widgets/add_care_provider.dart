import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/carbon_style_autocomplete.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';

import '../classes/specialities.dart';
import 'carbon_style_button.dart';

class AddCareProviderScreen extends StatefulWidget {
  const AddCareProviderScreen({super.key});

  @override
  State<AddCareProviderScreen> createState() => _AddCareProviderScreenState();
}

class _AddCareProviderScreenState extends State<AddCareProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSpecialtyLabel;
  String? _imageUrl;

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.startsWith('http')) {
      setState(() => _imageUrl = data.text);
    }
  }

  // Inside your Build method's Column:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Caregiver")),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(context: context, builder: (_) => _imageInputDialog());
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        border: Border.all(color: const Color(0xFF525252)),
                        borderRadius: BorderRadius.circular(4),
                        image: _imageUrl != null
                            ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _imageUrl == null
                          ? const Icon(Icons.add_a_photo, size: 30, color: Color(0xFF525252))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16), // Add spacing between image and inputs
                  Expanded(
                    // <--- THIS IS THE KEY
                    child: CarbonAutocomplete(
                      label: "Caregiver's Specialization",
                      // Pass only the keys (the display names) as the options
                      options: specialities.keys.toList(),
                      placeholder: "Enter the caregiver's title",
                      helperText: "Select from the available list.",
                      onChanged: (String? val) {
                        // 'val' will be the string the user typed or selected
                        print("Selected specialty: $val");

                        // If you need the underlying enum/value, look it up in your map:
                        // final underlyingValue = specialities[val];
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Spacing between the two text fields
              CarbonTextEdit(label: "First name", helperText: "Enter the first name"),
              CarbonTextEdit(label: "Last Name", helperText: "Enter the last name"),
              CarbonTextEdit(label: "Email", helperText: "enter an email in the form name@site.com"),
              CarbonTextEdit(label: "Other", helperText: "enter the fax, cell or pager number"),
              CarbonTextEdit(label: "Office Location", helperText: "enter the address of the provider"),
              CarbonTextEdit(label: "Notes", helperText: "enter anything you want to remember about the provider"),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CarbonButton(label: "Cancel", onPressed: () {}, isSecondary: true, color: Colors.black38),
                  ),
                  Expanded(
                    child: CarbonButton(label: "Save", icon: Symbols.save, onPressed: () {}),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageInputDialog() {
    TextEditingController controller = TextEditingController();
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: const Text("Add Photo"),
      insetPadding: EdgeInsets.all(0.0),
      contentPadding: EdgeInsetsGeometry.all(16.0),
      buttonPadding: EdgeInsetsGeometry.all(0.0),
      actionsPadding: EdgeInsetsGeometry.all(0.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarbonTextEdit(label: "Image URL"),
          const SizedBox(height: 16),
          TextButton(onPressed: _handlePaste, child: const Text("Paste from Clipboard")),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: CarbonButton(
                label: "Cancel",
                color: Colors.black38,
                isSecondary: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: CarbonButton(
                onPressed: () {
                  setState(() => _imageUrl = controller.text);
                  Navigator.pop(context);
                },
                label: "Save",
              ),
            ),
          ],
        ),
      ],
    );
  }
}
