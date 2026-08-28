import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';

import '../classes/care_plan_import.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/uuid.dart';

// The receiving end of Progressor's ally://import deep link — a physician's discharge
// care plan, handed to the caregiver by email, arrives here for review before anything
// touches the local database. The caregiver still has to pick which Ally profile it
// belongs to (a household may track more than one person) and can uncheck anything
// they don't want carried in, mirroring the same review-then-send pattern Progressor
// uses on the sending side.
class ImportCarePlanScreen extends StatefulWidget {
  final CarePlanImportPayload payload;

  const ImportCarePlanScreen({super.key, required this.payload});

  @override
  State<ImportCarePlanScreen> createState() => _ImportCarePlanScreenState();
}

class _ImportCarePlanScreenState extends State<ImportCarePlanScreen> {
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _loading = true;
  bool _importing = false;
  bool _imported = false;

  final Set<int> _excludedOrders = {};
  final Set<int> _excludedMedications = {};

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
      // Best-effort match on the incoming name — still requires the caregiver's
      // explicit confirmation before anything is written, never auto-selected silently.
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

  Future<void> _import() async {
    final Patient? patient = _selectedPatient;
    if (patient == null) return;
    setState(() => _importing = true);

    final db = DatabaseManager();
    for (int i = 0; i < widget.payload.medications.length; i++) {
      if (_excludedMedications.contains(i)) continue;
      final ImportedMedication med = widget.payload.medications[i];
      await db.insertMedication({
        'id': uuid.v4(),
        'patient_uuid': patient.patientUuid,
        'name': med.name,
        'dose': med.dose,
        'freq': med.freq,
      });
    }
    for (int i = 0; i < widget.payload.orders.length; i++) {
      if (_excludedOrders.contains(i)) continue;
      final ImportedOrder order = widget.payload.orders[i];
      await db.insertCareOrder(
        id: uuid.v4(),
        patientUuid: patient.patientUuid,
        label: order.label,
        directions: order.directions,
        frequency: order.frequency,
        source: 'Imported care plan',
      );
    }

    if (!mounted) return;
    setState(() {
      _importing = false;
      _imported = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Care Plan", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _imported
              ? _buildSuccess()
              : _buildReview(),
    );
  }

  Widget _buildSuccess() {
    final String name = _selectedPatient != null
        ? '${_selectedPatient!.firstName} ${_selectedPatient!.lastName}'
        : widget.payload.patientName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text("Care plan imported for $name", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: carbonColorButtonPrimary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(
            "Care plan sent for ${widget.payload.patientName}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        const Text("IMPORT INTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
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
        const SizedBox(height: 16),
        if (widget.payload.orders.isNotEmpty) ...[
          const Text("CARE ORDERS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
          ...widget.payload.orders.asMap().entries.map((entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: !_excludedOrders.contains(entry.key),
                onChanged: (val) => setState(() {
                  if (val == true) {
                    _excludedOrders.remove(entry.key);
                  } else {
                    _excludedOrders.add(entry.key);
                  }
                }),
                title: Text(entry.value.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: entry.value.directions != null ? Text(entry.value.directions!, style: const TextStyle(fontSize: 12)) : null,
              )),
          const SizedBox(height: 12),
        ],
        if (widget.payload.medications.isNotEmpty) ...[
          const Text("MEDICATIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
          ...widget.payload.medications.asMap().entries.map((entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: !_excludedMedications.contains(entry.key),
                onChanged: (val) => setState(() {
                  if (val == true) {
                    _excludedMedications.remove(entry.key);
                  } else {
                    _excludedMedications.add(entry.key);
                  }
                }),
                title: Text(entry.value.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${entry.value.dose ?? ''} ${entry.value.freq ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
              )),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_selectedPatient == null || _importing) ? null : _import,
            icon: _importing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Symbols.download, color: Colors.white),
            label: Text(_importing ? "Importing..." : "Import Care Plan", style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: carbonColorButtonPrimary),
          ),
        ),
      ],
    );
  }
}
