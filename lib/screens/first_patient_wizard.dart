import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/blood_type.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/listable.dart';
import '../widgets/blood_type_selector.dart';
import '../widgets/body_metrics_entry_widget.dart';
import '../widgets/carbon_button_compact.dart';
import '../widgets/carbon_style_button.dart';
import '../widgets/carbon_style_textbox.dart';

// The very first thing a real (non-demo) install shows. With zero patients in the
// roster every other screen has nothing to work with — see the "is my app bloated"
// investigation that surfaced this: DataSeeder is gated behind kDebugMode, so a real
// release build boots to a permanently blank roster with no way in. One small ask per
// page rather than the dense UserScreen this is deliberately avoiding replicating; name
// and date of birth are the only required step (matching AddPatientScreen's existing
// "quick add a family member" bar), everything else is skippable and can always be
// filled in later from UserScreen itself.
class FirstPatientWizard extends StatefulWidget {
  final VoidCallback onPatientCreated;

  const FirstPatientWizard({super.key, required this.onPatientCreated});

  @override
  State<FirstPatientWizard> createState() => _FirstPatientWizardState();
}

class _FirstPatientWizardState extends State<FirstPatientWizard> {
  static const int _stepCount = 6;
  final PageController _pageController = PageController();
  int _step = 0;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phnController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  DateTime? _dob;
  AboType _abo = AboType.o;
  RhFactor _rh = RhFactor.positive;
  bool _bloodTypeChosen = false;
  double? _weight;
  double? _height;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phnController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  bool get _nameStepValid =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _dob != null;

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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

  void _onAboChanged(Listable abo) {
    setState(() {
      _abo = abo as AboType;
      _bloodTypeChosen = true;
    });
  }

  void _onRhChanged(Listable rh) {
    setState(() {
      _rh = rh as RhFactor;
      _bloodTypeChosen = true;
    });
  }

  Future<void> _importFromContacts() async {
    final PermissionStatus status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      if (!mounted) return;
      setState(
        () => _error =
            "Contacts access wasn't granted — you can still type the address in below.",
      );
      return;
    }

    final List<Contact> contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.address},
    );
    final List<Contact> withAddress =
        contacts.where((c) => c.addresses.isNotEmpty).toList()..sort(
          (a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''),
        );

    if (!mounted) return;
    final Contact? picked = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ContactPickerSheet(contacts: withAddress),
    );
    if (picked == null || picked.addresses.isEmpty) return;

    final Address address = picked.addresses.first;
    setState(() {
      _streetController.text = address.street ?? '';
      _cityController.text = address.city ?? '';
      _provinceController.text = address.state ?? '';
      _postalCodeController.text = address.postalCode ?? '';
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final String patientUuid = await DatabaseManager().insertPatient(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dob: _dob!,
        phn: _phnController.text.trim(),
        abo: _bloodTypeChosen ? _abo : null,
        rh: _bloodTypeChosen ? _rh : null,
        streetAddress: _streetController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );
      if (_weight != null && _weight! > 0) {
        await DatabaseManager().insertPatientMetric(
          patientUuid,
          _weight!,
          'weight',
        );
      }
      if (_height != null && _height! > 0) {
        await DatabaseManager().insertPatientMetric(
          patientUuid,
          _height!,
          'height',
        );
      }
      widget.onPatientCreated();
    } catch (error) {
      setState(() {
        _saving = false;
        _error = 'Save failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: LinearProgressIndicator(
                value: (_step + 1) / _stepCount,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                color: AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _welcomeStep(),
                  _nameStep(),
                  _phnStep(),
                  _bloodTypeStep(),
                  _metricsStep(),
                  _addressStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page({
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onNext,
    String nextLabel = "Next",
    bool showSkip = true,
    bool showBack = true,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 8),
          Text(subtitle, style: CarbonTheme.carbonLabelTextStyle),
          const SizedBox(height: 24),
          child,
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: CarbonTheme.dangerTextStyle),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CarbonButton(
              label: nextLabel,
              alignment: MainAxisAlignment.center,
              style: CarbonButtonStyle.primary,
              onPressed: onNext,
            ),
          ),
          if (showSkip) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CarbonButton(
                label: "Skip",
                alignment: MainAxisAlignment.center,
                style: CarbonButtonStyle.secondary,
                onPressed: () => _goTo(_step + 1),
              ),
            ),
          ],
          if (showBack) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CarbonButton(
                label: "Back",
                alignment: MainAxisAlignment.center,
                style: CarbonButtonStyle.ghost,
                onPressed: () => _goTo(_step - 1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _welcomeStep() {
    return _page(
      title: "Welcome to CWICare Partner.",
      subtitle: "",
      showSkip: false,
      showBack: false,
      nextLabel: "Get Started",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This app does more than track your health—it helps keep you "
            "safe, deepens your understanding of your body and medical "
            "conditions, and empowers you to have more meaningful "
            "conversations with your care providers.",
            style: CarbonTheme.carbonTextStyle,
          ),
          const SizedBox(height: 16),
          Text(
            "Your privacy is paramount. All the data you collect stays "
            "secure right here on your personal device. CWICare does not "
            "partner with outside medical companies or share your "
            "information in any way. We may ask your permission to provide "
            "alerts and reminders, but those processes also remain "
            "entirely on your device.",
            style: CarbonTheme.carbonTextStyle,
          ),
          const SizedBox(height: 16),
          Text(
            "Your foundation for a healthier, fuller life starts here.",
            style: CarbonTheme.carbonTextStyle?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onNext: () => _goTo(_step + 1),
    );
  }

  Widget _nameStep() {
    return _page(
      title: "Let's get started",
      subtitle:
          "Who is this profile for? We just need a name and date of birth.",
      showSkip: false,
      showBack: false,
      child: Column(
        children: [
          CarbonTextInput(
            label: "First Name",
            controller: _firstNameController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          CarbonTextInput(
            label: "Last Name",
            controller: _lastNameController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: CarbonCompactButton(
              icon: Symbols.event,
              label: _dob == null
                  ? "Date of Birth"
                  : '${_dob!.month}/${_dob!.day}/${_dob!.year}',
              style: CarbonButtonStyle.secondary,
              onTap: _pickDob,
            ),
          ),
        ],
      ),
      onNext: _nameStepValid
          ? () => _goTo(_step + 1)
          : () => setState(
              () => _error =
                  "First name, last name, and date of birth are all required.",
            ),
    );
  }

  Widget _phnStep() {
    return _page(
      title: "Health Card Number",
      subtitle:
          "If you have it handy, add your government health card number. "
          "Totally optional — you can add this later.",
      child: CarbonTextInput(
        label: "Government Health Card #",
        controller: _phnController,
        onChanged: (_) {},
      ),
      onNext: () => _goTo(_step + 1),
    );
  }

  Widget _bloodTypeStep() {
    return _page(
      title: "Blood Type",
      subtitle: "Useful for emergency staff to know. Skip if you're not sure.",
      child: BloodTypeSelector(
        selectedAbo: _abo,
        selectedRh: _rh,
        onAboChanged: _onAboChanged,
        onRhChanged: _onRhChanged,
        showActions: false,
      ),
      onNext: () => _goTo(_step + 1),
    );
  }

  Widget _metricsStep() {
    return _page(
      title: "Weight & Height",
      subtitle:
          "Helps us track changes over time. Skip if you'd rather not say.",
      child: BodyMetricsEntryWidget(
        weight: _weight,
        height: _height,
        onMetricsChanged: (weight, height) {
          setState(() {
            _weight = weight;
            _height = height;
          });
        },
      ),
      onNext: () => _goTo(_step + 1),
    );
  }

  Widget _addressStep() {
    return _page(
      title: "Address",
      subtitle:
          "Useful for provider paperwork and emergencies. Type it in, pull it from "
          "your contacts, or skip entirely.",
      nextLabel: _saving ? "Saving..." : "Finish",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarbonCompactButton(
            icon: Symbols.contacts,
            label: "Import from Contacts",
            style: CarbonButtonStyle.secondary,
            onTap: _importFromContacts,
          ),
          const SizedBox(height: 16),
          CarbonTextInput(
            label: "Street Address",
            controller: _streetController,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          CarbonTextInput(
            label: "City",
            controller: _cityController,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          CarbonTextInput(
            label: "Province/State",
            controller: _provinceController,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          CarbonTextInput(
            label: "Postal/Zip Code",
            controller: _postalCodeController,
            onChanged: (_) {},
          ),
        ],
      ),
      onNext: _saving ? () {} : _save,
    );
  }
}

class _ContactPickerSheet extends StatelessWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text("Choose a Contact", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 8),
            Text(
              "Only contacts with a saved address are shown.",
              style: CarbonTheme.carbonLabelTextStyle,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: Text(
                        "No contacts with a saved address were found.",
                        style: CarbonTheme.carbonLabelTextStyle,
                      ),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final Contact contact = contacts[index];
                        return ListTile(
                          title: Text(contact.displayName ?? 'Unnamed'),
                          subtitle: Text(
                            contact.addresses.first.formatted ?? '',
                          ),
                          onTap: () => Navigator.of(context).pop(contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
