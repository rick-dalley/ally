import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/widgets/carbon_style_autocomplete.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/metric_value.dart';
import '../classes/provider.dart';
import '../classes/specialities.dart';
import 'carbon_style_button.dart';

class AddCareProviderScreen extends StatefulWidget {
  final String patientUuid;
  const AddCareProviderScreen({super.key, required this.patientUuid});

  @override
  State<AddCareProviderScreen> createState() => AddCareProviderScreenState();
}

class AddCareProviderScreenState extends State<AddCareProviderScreen> {
  String? imageUrl;
  late String patientUuid = widget.patientUuid;
  late Provider provider = Provider(id: uuid.toString(), patientUuid: patientUuid);
  late TextEditingController firstNameController = TextEditingController();
  late TextEditingController lastNameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController phoneController = TextEditingController();
  late TextEditingController cityController = TextEditingController();
  late TextEditingController postalCodeController = TextEditingController();
  late TextEditingController stateController = TextEditingController();
  late TextEditingController streetController = TextEditingController();
  late TextEditingController specialtyController = TextEditingController();
  late TextEditingController departmentController = TextEditingController();

  Future<void> handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.startsWith('http')) {
      setState(() => imageUrl = data.text);
      provider.patientUuid = widget.patientUuid;
      provider.image = NetworkImage(imageUrl!);
      provider.firstName = provider.firstName ?? '';
      provider.lastName = provider.lastName ?? '';
      provider.save();
    }
  }

  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();
  // Call this when the user taps "Select Doctor from Contacts"
  Future<void> showContactPicker() async {
    try {
      Contact? contact = await _contactPicker.selectContact();

      if (contact != null) {
        provider = Provider.fromContact(contact, patientUuid);
        firstNameController.text = provider.firstName ?? '';
        lastNameController.text = provider.lastName ?? '';
        phoneController.text = provider.phone ?? '';
        provider.save();
        // Do what you need with the selected doctor's info here
      }
    } catch (e) {}
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Caregiver"),
        actions: [
          CarbonIconButton(
            onPressed: () {
              showContactPicker();
            },
            icon: Symbols.import_contacts,
          ),
        ],
      ),
      backgroundColor: AppTheme.onPrimaryColor,
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
                      showDialog(context: context, builder: (_) => imageInputDialog());
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        border: Border.all(color: const Color(0xFF525252)),
                        borderRadius: BorderRadius.circular(4),
                        image: imageUrl != null
                            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl == null
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

                        // If you need the underlying enum/value, look it up in your map:
                        // final underlyingValue = specialities[val];
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Spacing between the two text fields
              CarbonTextInput(label: "First name", helperText: "Enter the first name", controller: firstNameController),
              CarbonTextInput(label: "Last Name", helperText: "Enter the last name", controller: lastNameController),
              CarbonTextInput(
                label: "Email",
                helperText: "enter an email in the form name@site.com",
                controller: emailController,
              ),
              CarbonTextInput(label: "Other", helperText: "enter the fax, cell or pager number"),
              CarbonTextInput(
                label: "Office Location",
                helperText: "enter the address of the provider",
                controller: streetController,
              ),
              CarbonTextInput(label: "Notes", helperText: "enter anything you want to remember about the provider"),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CarbonButton(label: "Cancel", onPressed: () {}, style: CarbonButtonStyle.secondary),
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

  Widget imageInputDialog() {
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
          CarbonTextInput(label: "Image URL"),
          const SizedBox(height: 16),
          TextButton(onPressed: handlePaste, child: const Text("Paste from Clipboard")),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: CarbonButton(
                label: "Cancel",
                style: CarbonButtonStyle.secondary,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: CarbonButton(
                onPressed: () {
                  setState(() => imageUrl = controller.text);
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
