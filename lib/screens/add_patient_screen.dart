import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../widgets/carbon_button_compact.dart';
import '../widgets/carbon_style_textbox.dart';

// Deliberately minimal — first/last name and date of birth, the bare minimum to start
// tracking a new family member. Everything else this app knows how to capture about a
// patient (address, health card number, primary caregiver...) belongs on the fuller
// "clerical" profile screen, a separate, not-yet-built task, not bolted onto this quick
// entry point.
class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final DateTime? dob = _dob;

    if (firstName.isEmpty || lastName.isEmpty || dob == null) {
      setState(() => _error = "First name, last name, and date of birth are all required.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final String newPatientUuid = await DatabaseManager().insertPatient(
        firstName: firstName,
        lastName: lastName,
        dob: dob,
      );
      if (mounted) Navigator.pop(context, newPatientUuid);
    } catch (error, stackTrace) {
      debugPrint('[AddPatientScreen] insertPatient failed: $error\n$stackTrace');
      if (mounted) setState(() { _saving = false; _error = 'Save failed: $error'; });
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a Family Member", style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarbonTextInput(label: "First Name", controller: _firstNameController, onChanged: (_) {}),
            const SizedBox(height: 16),
            CarbonTextInput(label: "Last Name", controller: _lastNameController, onChanged: (_) {}),
            const SizedBox(height: 16),
            CarbonCompactButton(
              icon: Symbols.event,
              label: _dob == null ? "Date of Birth" : _formatDate(_dob!),
              style: CarbonButtonStyle.secondary,
              onTap: _pickDob,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: CarbonTheme.dangerTextStyle),
            ],
            const SizedBox(height: 24),
            CarbonCompactButton(
              icon: Symbols.check,
              label: "Save",
              style: CarbonButtonStyle.primary,
              onTap: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
