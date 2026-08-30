import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import '../classes/patient_pain.dart';
import '../classes/phone.dart';
import '../classes/provider.dart';
import '../classes/reminder_registry.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';

// Which SymptomCarePlan chose to open this sheet — changes emphasis and ordering,
// not just copy: "phone for advice" wants a tap-to-call front and center, "schedule
// an appointment" wants the full provider contact card, "seek immediate help" wants
// the nearby-clinic finder to be the first thing the patient sees.
enum SeekCareSheetMode { advice, schedule, urgent }

// Honest paths only, since this app has no real scheduling-system integration: contact
// an existing care-team member directly (call or email — something that actually
// reaches them, not a silent local note) or find the nearest walk-in clinic/ER by
// handing off to the phone's own Maps app.
class SeekCareSheet extends StatefulWidget {
  final String patientUuid;
  final String bodyPart;
  final SeekCareSheetMode mode;
  final DetailedPainLevel? severity;
  final Frequency? frequency;

  const SeekCareSheet({
    super.key,
    required this.patientUuid,
    required this.bodyPart,
    required this.mode,
    this.severity,
    this.frequency,
  });

  @override
  State<SeekCareSheet> createState() => _SeekCareSheetState();
}

class _SeekCareSheetState extends State<SeekCareSheet> {
  late Future<List<Provider>> _providersFuture;
  Provider? _selectedProvider;
  bool _isLocating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _providersFuture = _loadProviders();
  }

  Future<List<Provider>> _loadProviders() async {
    final rows = await DatabaseManager().getProviders(widget.patientUuid);
    return rows
        .map((row) => Provider.fromJson(row))
        .where((p) => (p.email?.isNotEmpty ?? false) || (_phoneFor(p)?.number.isNotEmpty ?? false))
        .toList();
  }

  Phone? _phoneFor(Provider provider) => provider.getAvailablePhone(preferred: PhoneTypes.office);

  Future<void> _emailProvider(Provider provider) async {
    final String symptomSummary = widget.severity?.label ?? "noticeable";
    final String frequencySummary = widget.frequency?.label.toLowerCase() ?? "on and off";

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: provider.email,
      queryParameters: {
        'subject': 'Recent occurrence of pain c/o doctor ${provider.firstName} ${provider.lastName}',
        'body':
            'Hi Dr. ${provider.lastName},\n\n'
            "I've been experiencing $symptomSummary pain in my ${widget.bodyPart}. "
            'It happens $frequencySummary. '
            "I'd like to make an appointment to have it looked at.",
      },
    );

    // A local reminder-to-self that this was requested — not a real booking, since
    // there's no scheduling-system integration to actually confirm a time.
    await DatabaseManager().insertAppointment(
      patientUuid: widget.patientUuid,
      providerUuid: provider.id,
      scheduledFor: DateTime.now().add(const Duration(days: 1)),
      reason: '${widget.bodyPart} pain',
      notes: 'Requested by email from the Symptoms screen; not yet confirmed by the office.',
    );
    // Pop before refreshing reminders, not after — see BookAppointmentSheet._book for
    // the full explanation. refresh()'s notifyListeners() can trigger HomeScreen's own
    // auto-popup ReminderSheet on this same Navigator, and Navigator.pop() always pops
    // whatever's currently on top of the stack.
    if (mounted) Navigator.pop(context);
    await ReminderRegistry.instance.refresh();

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _callProvider(Provider provider) async {
    final Phone? phone = _phoneFor(provider);
    if (phone == null || phone.number.isEmpty) return;
    final Uri telUri = Uri(scheme: 'tel', path: phone.number);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openWebsite(String website) async {
    final String normalized = website.startsWith('http://') || website.startsWith('https://')
        ? website
        : 'https://$website';
    final Uri uri = Uri.parse(normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _findNearbyCare() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Turn on location services to find the nearest clinic.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "Location permission is needed to find the nearest clinic.";
      }

      final position = await Geolocator.getCurrentPosition();
      await _launchNearbySearch('urgent care', position.latitude, position.longitude);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _locationError = error.toString());
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _launchNearbySearch(String query, double lat, double lng) async {
    final String encodedQuery = Uri.encodeComponent(query);
    final Uri primary = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse('https://maps.apple.com/?q=$encodedQuery&sll=$lat,$lng&z=14')
        : Uri.parse('geo:$lat,$lng?q=$encodedQuery');

    if (await canLaunchUrl(primary)) {
      await launchUrl(primary, mode: LaunchMode.externalApplication);
      return;
    }

    // Falls back to the Google Maps web link if no native maps app answers — works
    // from a browser on any platform, including where geo:/maps.apple.com don't.
    final Uri fallback = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$query near $lat,$lng")}',
    );
    await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }

  String get _title => switch (widget.mode) {
    SeekCareSheetMode.advice => "Get Advice",
    SeekCareSheetMode.schedule => "Get This Looked At",
    SeekCareSheetMode.urgent => "Find Care Now",
  };

  String get _subtitle => switch (widget.mode) {
    SeekCareSheetMode.advice => "Who do you want to call about your ${widget.bodyPart}?",
    SeekCareSheetMode.schedule => "Who do you want to see about your ${widget.bodyPart}?",
    SeekCareSheetMode.urgent => "Let's find you care for your ${widget.bodyPart} right away.",
  };

  @override
  Widget build(BuildContext context) {
    final providerSection = _buildProviderSection();
    final nearbySection = _buildNearbySection();
    final bool urgentFirst = widget.mode == SeekCareSheetMode.urgent;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 8),
          Text(_subtitle, style: CarbonTheme.carbonHintTextStyle),
          const SizedBox(height: 24),
          if (urgentFirst) ...[nearbySection, const SizedBox(height: 24), const Divider(), const SizedBox(height: 8)],
          Text(
            urgentFirst ? "Or, contact your care team:" : "My care team",
            style: CarbonTheme.carbonLabelTextStyle,
          ),
          const SizedBox(height: 12),
          providerSection,
          if (!urgentFirst) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text("Or, if this needs attention now:", style: CarbonTheme.carbonLabelTextStyle),
            const SizedBox(height: 12),
            nearbySection,
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    return FutureBuilder<List<Provider>>(
      future: _providersFuture,
      builder: (context, snapshot) {
        final providers = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator());
        }
        if (providers.isEmpty) {
          return Text("No care team members with contact info on file yet.", style: CarbonTheme.carbonHelperTextStyle);
        }
        // Defaults to the first provider so the dropdown always has a concrete value
        // (matching every other CarbonDropdown in this app) without mutating state
        // during build.
        final Provider effectiveProvider = _selectedProvider ?? providers.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarbonDropdown<_ProviderChoice>(
              label: "Choose a doctor",
              placeholder: "Choose a doctor",
              helperText: "",
              items: providers.map((p) => _ProviderChoice(p)).toList(),
              value: _ProviderChoice(effectiveProvider),
              onChanged: (Listable val) {
                setState(() => _selectedProvider = (val as _ProviderChoice).provider);
              },
            ),
            const SizedBox(height: 12),
            _providerContactCard(effectiveProvider),
            const SizedBox(height: 12),
            _providerActions(effectiveProvider),
          ],
        );
      },
    );
  }

  Widget _providerContactCard(Provider provider) {
    final Phone? phone = _phoneFor(provider);
    final bool hasImage = provider.image != null && provider.image!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: hasImage ? MemoryImage(provider.image!) : null,
          child: hasImage ? null : const Icon(Symbols.person),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.fullName, style: CarbonTheme.carbonLabelTextStyle),
              if (provider.position != null && provider.position!.isNotEmpty)
                Text(provider.position!, style: CarbonTheme.carbonHelperTextStyle),
              if (phone != null && phone.number.isNotEmpty)
                InkWell(onTap: () => _callProvider(provider), child: Text(phone.number, style: _linkStyle)),
              if (provider.email != null && provider.email!.isNotEmpty)
                InkWell(onTap: () => _emailProvider(provider), child: Text(provider.email!, style: _linkStyle)),
              if (provider.website != null && provider.website!.isNotEmpty)
                InkWell(onTap: () => _openWebsite(provider.website!), child: Text(provider.website!, style: _linkStyle)),
            ],
          ),
        ),
      ],
    );
  }

  static const TextStyle _linkStyle = TextStyle(
    color: carbonColorBorderInteractive,
    decoration: TextDecoration.underline,
  );

  Widget _providerActions(Provider provider) {
    final bool hasEmail = provider.email != null && provider.email!.isNotEmpty;
    final bool hasPhone = (_phoneFor(provider)?.number.isNotEmpty ?? false);
    // Advice mode wants a call to be the fast/obvious action; schedule mode wants
    // email (since that's what actually logs a local appointment request) primary.
    final bool callIsPrimary = widget.mode == SeekCareSheetMode.advice || !hasEmail;

    final List<Widget> buttons = [];
    if (hasPhone) {
      buttons.add(
        CarbonCompactButton(
          icon: Symbols.call,
          label: "Call ${provider.fullName}",
          style: callIsPrimary ? CarbonButtonStyle.primary : CarbonButtonStyle.secondary,
          onTap: () => _callProvider(provider),
        ),
      );
    }
    if (hasEmail && widget.mode != SeekCareSheetMode.advice) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(
        CarbonCompactButton(
          icon: Symbols.mail,
          label: "Email This Doctor",
          style: callIsPrimary ? CarbonButtonStyle.secondary : CarbonButtonStyle.primary,
          onTap: () => _emailProvider(provider),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: buttons);
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarbonCompactButton(
          icon: Symbols.location_on,
          label: _isLocating ? "Finding nearby care..." : "Find a Walk-in Clinic or ER Near Me",
          style: widget.mode == SeekCareSheetMode.urgent ? CarbonButtonStyle.primary : CarbonButtonStyle.secondary,
          onTap: _isLocating ? null : _findNearbyCare,
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Text(_locationError!, style: CarbonTheme.dangerTextStyle),
        ],
      ],
    );
  }
}

class _ProviderChoice implements Listable {
  final Provider provider;
  const _ProviderChoice(this.provider);

  @override
  String get label => "Dr. ${provider.firstName ?? ''} ${provider.lastName ?? ''}".trim();

  @override
  String get description => provider.position ?? '';

  @override
  bool operator ==(Object other) => other is _ProviderChoice && other.provider.id == provider.id;

  @override
  int get hashCode => provider.id.hashCode;
}
