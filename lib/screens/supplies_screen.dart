import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/patient_supply.dart';
import '../classes/reminder_registry.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import '../widgets/supply_catalog_picker_sheet.dart';
import '../widgets/supply_detail_sheet.dart';

class SuppliesScreen extends StatefulWidget {
  final Patient user;
  const SuppliesScreen({super.key, required this.user});

  @override
  State<SuppliesScreen> createState() => SuppliesScreenState();
}

class SuppliesScreenState extends State<SuppliesScreen> {
  List<PatientSupply> _tracked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseManager().getPatientSupplies(widget.user.patientUuid);
    if (!mounted) return;
    setState(() {
      _tracked = rows.map(PatientSupply.fromRow).toList();
      _loading = false;
    });
  }

  Future<void> _addSupply() async {
    final PatientSupply? chosen = await showModalBottomSheet<PatientSupply>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SupplyCatalogPickerSheet(patientUuid: widget.user.patientUuid),
    );
    if (chosen == null || !mounted) return;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SupplyDetailSheet(patientUuid: widget.user.patientUuid, supply: chosen),
    );
    await _load();
  }

  Future<void> _edit(PatientSupply supply) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SupplyDetailSheet(patientUuid: widget.user.patientUuid, supply: supply),
    );
    await _load();
  }

  Future<void> _adjustQuantity(PatientSupply supply, int delta) async {
    final int newQuantity = (supply.quantityOnHand + delta).clamp(0, 1 << 30);
    await DatabaseManager().updatePatientSupply(
      PatientSupply(
        id: supply.id,
        name: supply.name,
        category: supply.category,
        quantityOnHand: newQuantity,
        reorderThreshold: supply.reorderThreshold,
        linkedMedicationId: supply.linkedMedicationId,
      ),
    );
    await ReminderRegistry.instance.refresh();
    await _load();
  }

  // No supplier search, no price comparison, no automated requisition — just hands
  // off to the phone's own SMS composer addressed to whatever pharmacy is on file,
  // or a plain web search if there isn't one. Honest about what this app actually is:
  // no backend, no supplier integrations, on-device only by design.
  Future<void> _reorder(PatientSupply supply) async {
    final String message = "Hi, I'd like to reorder: ${supply.name}. Thank you.";
    final String phone = widget.user.pharmacyPhone;

    if (phone.isNotEmpty) {
      final Uri smsUri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return;
      }
    }

    final Uri searchUri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent("buy ${supply.name}")}');
    await launchUrl(searchUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: AlignmentGeometry.centerLeft,
          child: Text("Supplies", style: CarbonTheme.carbonLabelTextStyle),
        ),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tracked.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Nothing tracked yet. Tap + to add a supply — needles, swabs, test strips, and the like.",
                  style: CarbonTheme.carbonHelperTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tracked.length,
              itemBuilder: (context, index) => _buildTile(_tracked[index]),
            ),
      floatingActionButton: FloatingActionButton(onPressed: _addSupply, child: const Icon(Symbols.add)),
    );
  }

  Widget _buildTile(PatientSupply supply) {
    final Color accent = supply.isLow ? carbonColorSupportError : carbonColorTextPrimary;
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _edit(supply),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(supply.icon, size: 20, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      supply.name,
                      style: CarbonTheme.carbonLabelTextStyle?.copyWith(fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.remove, size: 18),
                    onPressed: () => _adjustQuantity(supply, -1),
                  ),
                  Text('${supply.quantityOnHand}', style: CarbonTheme.carbonFieldTextStyle?.copyWith(color: accent)),
                  IconButton(
                    icon: const Icon(Symbols.add, size: 18),
                    onPressed: () => _adjustQuantity(supply, 1),
                  ),
                ],
              ),
              if (supply.isLow) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Running low — at or below your reorder point of ${supply.reorderThreshold}.",
                        style: CarbonTheme.dangerTextStyle,
                      ),
                    ),
                    CarbonCompactButton(
                      icon: Symbols.send,
                      label: "Reorder",
                      width: 120,
                      style: CarbonButtonStyle.secondary,
                      onTap: () => _reorder(supply),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
