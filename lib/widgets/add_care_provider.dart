import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/widgets/avatar_picker.dart';
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

  void handleAvatarPicked(Uint8List? image) {
    setState(() {
      provider.image = image;
      provider.save();
    });
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context, provider)),
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
      backgroundColor: carbonColorScaffoldBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                children: [
                  AvatarPicker(onPicked: handleAvatarPicked),
                  const SizedBox(width: 16), // Add spacing between image and inputs
                  Expanded(
                    child: CarbonAutocomplete(
                      label: "Caregiver's Specialization",
                      // Pass only the keys (the display names) as the options
                      options: Specialities.values,
                      placeholder: "Enter the caregiver's title",
                      helperText: "Select from the available list.",
                      onChanged: (String? val) {
                        provider.specialities = val;
                        provider.save();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Spacing between the two text fields
              CarbonTextInput(
                label: "First name",
                helperText: "Enter the first name",
                controller: firstNameController,
                onChanged: (String value) {
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Last Name",
                helperText: "Enter the last name",
                controller: lastNameController,
                onChanged: (String value) {
                  provider.save();
                },
              ),
              const SizedBox(height: 8.0),
              CarbonTextInput(
                label: "Office Phone",
                helperText: "Enter the main office phone number",
                controller: phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (String value) {
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Other Phone",
                helperText: "Enter the fax, cell or pager number",
                controller: phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (String value) {
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Office eMail",
                helperText: "enter an email in the form name@site.com",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (String value) {
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Office Location",
                helperText: "enter the address of the provider",
                controller: streetController,
                keyboardType: TextInputType.streetAddress,
                onChanged: (String value) {
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Notes",
                helperText: "Enter anything you want to remember about the provider",
                onChanged: (String value) {
                  provider.save();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
