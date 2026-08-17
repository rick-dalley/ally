import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/interfaces/listable.dart';
import '../classes/patient.dart';
import '../classes/provider.dart';
import '../classes/release_of_information_report.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';
import '../widgets/report_preview_screen.dart';

class ReleaseOfInformationScreen extends StatefulWidget {
  final Patient patient;
  const ReleaseOfInformationScreen({super.key, required this.patient});

  @override
  State<ReleaseOfInformationScreen> createState() => _ReleaseOfInformationScreenState();
}

class _ReleaseOfInformationScreenState extends State<ReleaseOfInformationScreen> {
  late Future<List<_ProviderChoice>> _providersFuture;
  Provider? _selectedProvider;
  final TextEditingController _whatController = TextEditingController(text: "Complete medical record.");
  final TextEditingController _sendToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _providersFuture = DatabaseManager().getProviders(widget.patient.patientUuid).then((rows) {
      final List<_ProviderChoice> choices = rows.map((row) => _ProviderChoice(Provider.fromJson(row))).toList();
      // Defaults to the first provider so the button works the instant the list loads,
      // rather than silently doing nothing until the patient explicitly taps the
      // dropdown — same reasoning as SeekCareSheet's provider default.
      if (choices.isNotEmpty && mounted) {
        setState(() => _selectedProvider = choices.first.provider);
      }
      return choices;
    });
  }

  @override
  void dispose() {
    _whatController.dispose();
    _sendToController.dispose();
    super.dispose();
  }

  void _generate() {
    final Provider? provider = _selectedProvider;
    if (provider == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          title: "Release of Information Request",
          buildPdf: () => ReleaseOfInformationReport.build(
            patient: widget.patient,
            requestedFrom: provider,
            whatIsRequested: _whatController.text,
            sendTo: _sendToController.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request Records", style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "A plainly-worded request you can hand to a doctor's office — not a "
                "completed legal authorization. Their office may still need you to sign "
                "their own release form in person.",
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<_ProviderChoice>>(
                future: _providersFuture,
                builder: (context, snapshot) {
                  final choices = snapshot.data ?? const [];
                  if (choices.isEmpty) return const SizedBox.shrink();
                  final _ProviderChoice current = _selectedProvider != null
                      ? _ProviderChoice(_selectedProvider!)
                      : choices.first;
                  return CarbonDropdown(
                    label: "Requesting From",
                    value: current,
                    items: choices,
                    onChanged: (Listable val) => setState(() => _selectedProvider = (val as _ProviderChoice).provider),
                  );
                },
              ),
              const SizedBox(height: 16),
              CarbonTextInput(
                label: "What are you requesting?",
                controller: _whatController,
                maxLines: 3,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              CarbonTextInput(
                label: "Send results to (optional)",
                helperText: "Leave blank to have results sent to you.",
                placeHolderText: "e.g. Dr. Smith, 123 Main St.",
                controller: _sendToController,
                maxLines: 2,
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              CarbonCompactButton(
                icon: Symbols.description,
                label: "Generate Request",
                style: CarbonButtonStyle.primary,
                onTap: _selectedProvider == null ? () {} : _generate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderChoice implements Listable {
  final Provider provider;
  const _ProviderChoice(this.provider);

  @override
  String get label => provider.fullName;

  @override
  String get description => provider.position ?? '';

  @override
  bool operator ==(Object other) => other is _ProviderChoice && other.provider.id == provider.id;

  @override
  int get hashCode => provider.id.hashCode;
}
