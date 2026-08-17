import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/provider.dart';
import '../classes/vision_prescription.dart';
import '../widgets/vision_prescription_sheet.dart';

// The whole point of this screen is being pulled up and handed to someone else in a
// few seconds — an optician, a retailer — so the numbers are the main event, shown big
// and plain, not tucked behind another tap. History (old, superseded prescriptions)
// is available but visually secondary to whichever is current per type.
class EyeCareScreen extends StatefulWidget {
  final Patient user;
  const EyeCareScreen({super.key, required this.user});

  @override
  State<EyeCareScreen> createState() => EyeCareScreenState();
}

class EyeCareScreenState extends State<EyeCareScreen> {
  List<VisionPrescription> _all = [];
  Map<String, String> _providerNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseManager().getVisionPrescriptionsForPatient(widget.user.patientUuid);
    final providerRows = await DatabaseManager().getProviders(widget.user.patientUuid);
    if (!mounted) return;
    setState(() {
      _all = rows.map(VisionPrescription.fromRow).toList();
      _providerNames = {
        for (final row in providerRows)
          (row['provider_uuid'] as String): Provider.fromJson(row).fullName,
      };
      _loading = false;
    });
  }

  Future<void> _add() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => VisionPrescriptionSheet(patientUuid: widget.user.patientUuid),
    );
    await _load();
  }

  Future<void> _edit(VisionPrescription rx) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => VisionPrescriptionSheet(patientUuid: widget.user.patientUuid, existing: rx),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final Map<VisionPrescriptionType, List<VisionPrescription>> byType = {
      for (final type in VisionPrescriptionType.values) type: _all.where((r) => r.type == type).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: AlignmentGeometry.centerLeft,
          child: Text("Eye Care", style: CarbonTheme.carbonLabelTextStyle),
        ),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "No prescriptions on file yet. Tap + to add your glasses or contacts prescription.",
                  style: CarbonTheme.carbonHelperTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final type in VisionPrescriptionType.values)
                  if (byType[type]!.isNotEmpty) _buildTypeSection(type, byType[type]!),
              ],
            ),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Symbols.add)),
    );
  }

  Widget _buildTypeSection(VisionPrescriptionType type, List<VisionPrescription> records) {
    final VisionPrescription current = records.first; // latest, list is issued_date DESC
    final List<VisionPrescription> history = records.skip(1).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, size: 20, color: carbonColorIconInterActive),
              const SizedBox(width: 8),
              Text(type.label, style: CarbonTheme.carbonHeadingTextStyle),
            ],
          ),
          const SizedBox(height: 8),
          _currentCard(current),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Previous", style: CarbonTheme.carbonHelperTextStyle),
            ...history.map(
              (rx) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_formatDate(rx.issuedDate), style: CarbonTheme.carbonHelperTextStyle),
                trailing: const Icon(Symbols.chevron_right, size: 18),
                onTap: () => _edit(rx),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _currentCard(VisionPrescription rx) {
    final bool expired = rx.isExpired;
    final Color accent = expired ? carbonColorSupportError : carbonColorTextPrimary;

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: () => _edit(rx),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rx.providerUuid != null && _providerNames[rx.providerUuid] != null)
                Text("Prescribed by ${_providerNames[rx.providerUuid]}", style: CarbonTheme.carbonHelperTextStyle),
              const SizedBox(height: 8),
              _eyeValueRow("Right Eye (OD)", rx.odSphere, rx.odCylinder, rx.odAxis, rx.odAdd, accent),
              const SizedBox(height: 4),
              _eyeValueRow("Left Eye (OS)", rx.osSphere, rx.osCylinder, rx.osAxis, rx.osAdd, accent),
              if (rx.pd != null) ...[
                const SizedBox(height: 4),
                Text("PD: ${rx.pd}", style: CarbonTheme.carbonTextStyle),
              ],
              if (rx.type == VisionPrescriptionType.contacts && (rx.baseCurve != null || rx.diameter != null)) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (rx.baseCurve != null) "Base Curve: ${rx.baseCurve}",
                    if (rx.diameter != null) "Diameter: ${rx.diameter}",
                  ].join('   '),
                  style: CarbonTheme.carbonTextStyle,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                expired
                    ? "Expired ${_formatDate(rx.expiryDate)}"
                    : rx.expiryDate != null
                    ? "Expires ${_formatDate(rx.expiryDate)}"
                    : "No expiry date on file",
                style: expired ? CarbonTheme.dangerTextStyle : CarbonTheme.carbonHelperTextStyle,
              ),
              if (rx.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(rx.notes, style: CarbonTheme.carbonHelperTextStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyeValueRow(String label, double? sphere, double? cylinder, int? axis, double? add, Color color) {
    final bool hasAny = sphere != null || cylinder != null || axis != null || add != null;
    if (!hasAny) return const SizedBox.shrink();
    final String value = [
      if (sphere != null) "SPH ${sphere >= 0 ? '+' : ''}$sphere",
      if (cylinder != null) "CYL ${cylinder >= 0 ? '+' : ''}$cylinder",
      if (axis != null) "AXIS $axis",
      if (add != null) "ADD ${add >= 0 ? '+' : ''}$add",
    ].join('   ');
    return Text(
      "$label:  $value",
      style: CarbonTheme.carbonFieldTextStyle?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }

  String _formatDate(DateTime? date) => date == null ? "—" : '${date.month}/${date.day}/${date.year}';
}
