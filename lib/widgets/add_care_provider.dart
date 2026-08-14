import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/phone.dart';
import 'package:triage/widgets/avatar_picker.dart';
import 'package:triage/widgets/carbon_style_autocomplete.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';
import '../classes/cancellation_policy.dart';
import '../classes/listable.dart';
import '../classes/provider.dart';
import '../classes/specialities.dart';
import '../classes/uuid.dart';
import 'carbon_style_button.dart';
import 'carbon_style_dropdown.dart';

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
  late TextEditingController websiteController = TextEditingController();
  late TextEditingController phoneController = TextEditingController();
  late TextEditingController otherPhoneController = TextEditingController();
  late TextEditingController streetController = TextEditingController();
  late TextEditingController notesController = TextEditingController();
  late TextEditingController cancellationNoticeController = TextEditingController();

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
        actions: [CarbonIconButton(onPressed: () {}, icon: Symbols.import_contacts)],
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
                  provider.firstName = value;
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Last Name",
                helperText: "Enter the last name",
                controller: lastNameController,
                onChanged: (String value) {
                  provider.lastName = value;
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
                  provider.setPhone(PhoneTypes.office, value);
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Other Phone",
                helperText: "Enter the fax, cell or pager number",
                controller: otherPhoneController,
                keyboardType: TextInputType.phone,
                onChanged: (String value) {
                  provider.setPhone(PhoneTypes.other, value);
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Office eMail",
                helperText: "enter an email in the form name@site.com",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (String value) {
                  provider.email = value;
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Website",
                helperText: "enter the practice or office website, if there is one",
                controller: websiteController,
                keyboardType: TextInputType.url,
                onChanged: (String value) {
                  provider.website = value;
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Office Location",
                helperText: "enter the address of the provider",
                controller: streetController,
                keyboardType: TextInputType.streetAddress,
                onChanged: (String value) {
                  provider.setStreet(value);
                  provider.save();
                },
              ),
              CarbonTextInput(
                label: "Notes",
                helperText: "Enter anything you want to remember about the provider",
                controller: notesController,
                onChanged: (String value) {
                  provider.purpose = value;
                  provider.save();
                },
              ),
              const SizedBox(height: 16.0),
              CarbonDropdown<CancellationBillingPolicy>(
                label: "Cancellation Policy",
                placeholder: "If a late cancellation is billed",
                helperText: "What happens if you cancel without enough notice",
                items: CancellationBillingPolicy.values,
                value: provider.cancellationPolicy ?? CancellationBillingPolicy.partial,
                onChanged: (Listable val) {
                  setState(() {
                    provider.cancellationPolicy = val as CancellationBillingPolicy;
                    provider.save();
                  });
                },
              ),
              CarbonTextInput(
                label: "Cancellation Notice (hours)",
                helperText: "How many hours' notice this provider requires to cancel or reschedule",
                controller: cancellationNoticeController,
                keyboardType: TextInputType.number,
                onChanged: (String value) {
                  provider.cancellationNoticeHours = int.tryParse(value);
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
