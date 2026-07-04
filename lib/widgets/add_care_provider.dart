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
              GestureDetector(
                onTap: () {
                  // Show a small dialog to input URL or trigger paste
                  showDialog(context: context, builder: (_) => _imageInputDialog());
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                  child: _imageUrl == null ? const Icon(Icons.add_a_photo, size: 40) : null,
                ),
              ),
              CarbonText(label: "First name", helperText: "enter the first name"),
              CarbonText(label: "Last Name", helperText: "enter the last name"),
              CarbonAutocomplete(
                label: "Caregiver's Specialization",
                // Pass only the keys (the display names) as the options
                options: specialities.keys.toList(),
                placeholder: 'Choose one...',
                helperText: 'Please select from the available list.',
                onChanged: (String? val) {
                  // 'val' will be the string the user typed or selected
                  print("Selected specialty: $val");

                  // If you need the underlying enum/value, look it up in your map:
                  // final underlyingValue = specialities[val];
                },
              ),
              SizedBox(height: 16),
              CarbonText(label: "Email", helperText: "enter an email in the form name@site.com"),
              CarbonText(label: "Other", helperText: "enter the fax, cell or pager number"),
              CarbonText(label: "Office Location", helperText: "enter the address of the provider"),
              CarbonText(label: "Notes", helperText: "enter anything you want to remember about the provider"),
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
      title: const Text("Add Photo"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Image URL"),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _handlePaste, child: const Text("Paste from Clipboard")),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _imageUrl = controller.text);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
