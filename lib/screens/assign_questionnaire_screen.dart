import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';

import '../classes/assigned_questionnaire_import.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/questionnaire_catalog.dart';
import '../classes/uuid.dart';

// The receiving end of Progressor's ally://assignQuestionnaire deep link — mirrors
// ImportCarePlanScreen's shape exactly (patient picker + explicit confirm before
// anything touches the local database). This is the *only* way a questionnaire ever
// becomes visible in Ally at all — there's no free-standing catalog to browse; see
// medical_profile_screen.dart and questionnaires_screen.dart.
class AssignQuestionnaireScreen extends StatefulWidget {
  final AssignedQuestionnairePayload payload;

  const AssignQuestionnaireScreen({super.key, required this.payload});

  @override
  State<AssignQuestionnaireScreen> createState() => _AssignQuestionnaireScreenState();
}

class _AssignQuestionnaireScreenState extends State<AssignQuestionnaireScreen> {
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _loading = true;
  bool _assigning = false;
  bool _assigned = false;

  QuestionnaireCatalogEntry? get _entry => questionnaireCatalogEntry(widget.payload.templateId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseManager().getAllPatientsWithVitals();
    final List<Patient> loaded = rows.map((r) => Patient.fromJson(r)).toList();
    if (!mounted) return;
    setState(() {
      _patients = loaded;
      final String incoming = widget.payload.patientName.trim().toLowerCase();
      for (final Patient p in loaded) {
        if ('${p.firstName} ${p.lastName}'.trim().toLowerCase() == incoming) {
          _selectedPatient = p;
          break;
        }
      }
      _loading = false;
    });
  }

  Future<void> _assign() async {
    final Patient? patient = _selectedPatient;
    if (patient == null) return;
    setState(() => _assigning = true);

    await DatabaseManager().insertAssignedQuestionnaire(
      id: uuid.v4(),
      patientUuid: patient.patientUuid,
      templateId: widget.payload.templateId,
      providerName: widget.payload.providerName,
      providerEmail: widget.payload.providerEmail,
    );

    if (!mounted) return;
    setState(() {
      _assigning = false;
      _assigned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Questionnaire Request", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assigned
              ? _buildSuccess()
              : _buildReview(),
    );
  }

  Widget _buildSuccess() {
    final String name = _selectedPatient != null ? '${_selectedPatient!.firstName} ${_selectedPatient!.lastName}' : widget.payload.patientName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "Ready for $name on the Questionnaires tile",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: carbonColorButtonPrimary),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final QuestionnaireCatalogEntry? entry = _entry;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: carbonColorButtonPrimary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(
            "${widget.payload.providerName} asked ${widget.payload.patientName} to complete "
            "${entry?.name ?? widget.payload.templateId}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        if (entry != null) ...[
          const SizedBox(height: 8),
          Text(entry.subTitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
        const SizedBox(height: 16),
        const Text("ASSIGN TO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 6),
        _patients.isEmpty
            ? const Text("No profiles yet — add a family member in Ally first.", style: TextStyle(fontSize: 13))
            : DropdownButtonFormField<Patient>(
                initialValue: _selectedPatient,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                hint: const Text("Choose a profile"),
                items: _patients
                    .map((p) => DropdownMenuItem(value: p, child: Text('${p.firstName} ${p.lastName}', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (p) => setState(() => _selectedPatient = p),
              ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_selectedPatient == null || _assigning) ? null : _assign,
            icon: _assigning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Symbols.checklist, color: Colors.white),
            label: Text(_assigning ? "Setting up..." : "Accept Request", style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: carbonColorButtonPrimary),
          ),
        ),
      ],
    );
  }
}
