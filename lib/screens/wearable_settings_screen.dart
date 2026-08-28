import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

import '../classes/alertable.dart';
import '../classes/care_order.dart';
import '../classes/database_manager.dart';
import '../classes/emergency_target.dart';
import '../classes/patient.dart';
import '../classes/uuid.dart';

// The wearable control panel: pairing status, which of the patient's active care
// orders (see care_order.dart's Notifiable) get pushed as a wearable notification, and
// the panic-button setup — which triggers are armed (Alertable, alertable.dart) and
// who they notify (EmergencyTarget, emergency_target.dart). Pairing itself is a
// stand-in — there's no real wearable to pair with yet (the hardware is still being
// sourced), so this just records a device name and a paired flag; the actual
// BLE/companion-app sync is separate, future work.
class WearableSettingsScreen extends StatefulWidget {
  final Patient patient;

  const WearableSettingsScreen({super.key, required this.patient});

  @override
  State<WearableSettingsScreen> createState() => _WearableSettingsScreenState();
}

class _WearableSettingsScreenState extends State<WearableSettingsScreen> {
  bool _loading = true;
  bool _paired = false;
  String _deviceName = '';
  List<WearableAlertConfig> _alerts = [];
  List<CareOrder> _orders = [];
  List<EmergencyTarget> _targets = [];

  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = DatabaseManager();
    final Map<String, dynamic> settingsRow = await db.getOrCreateWearableSettings(widget.patient.patientUuid);
    final List<Map<String, dynamic>> orderRows = await db.getCareOrdersForPatient(widget.patient.patientUuid);
    final List<Map<String, dynamic>> targetRows = await db.getEmergencyTargetsForPatient(widget.patient.patientUuid);
    if (!mounted) return;
    setState(() {
      _paired = (settingsRow['paired'] as int? ?? 0) == 1;
      _deviceName = settingsRow['device_name'] as String? ?? '';
      _deviceNameController.text = _deviceName;
      _alerts = alertConfigsFromRow(settingsRow);
      _orders = orderRows.map(CareOrder.fromRow).toList();
      _targets = targetRows.map(EmergencyTarget.fromRow).toList();
      _loading = false;
    });
  }

  Future<void> _togglePairing(bool paired) async {
    setState(() => _paired = paired);
    await DatabaseManager().setWearablePairing(
      patientUuid: widget.patient.patientUuid,
      paired: paired,
      deviceName: _deviceNameController.text.trim().isEmpty ? null : _deviceNameController.text.trim(),
    );
  }

  Future<void> _saveDeviceName() async {
    if (!_paired) return;
    await DatabaseManager().setWearablePairing(patientUuid: widget.patient.patientUuid, paired: true, deviceName: _deviceNameController.text.trim());
  }

  Future<void> _toggleOrderSync(CareOrder order, bool enabled) async {
    await DatabaseManager().setCareOrderWearableSync(orderId: order.notifiableId, enabled: enabled);
    await _load();
  }

  Future<void> _toggleAlert(WearableAlertConfig alert, bool enabled) async {
    final String column = switch (alert.trigger) {
      AlertTrigger.manual => 'alert_manual_enabled',
      AlertTrigger.fall => 'alert_fall_enabled',
      AlertTrigger.slap => 'alert_slap_enabled',
    };
    await DatabaseManager().setAlertTriggerEnabled(patientUuid: widget.patient.patientUuid, column: column, enabled: enabled);
    await _load();
  }

  Future<void> _addTarget() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Add Emergency Contact", style: CarbonTheme.carbonHeadingTextStyle),
            const SizedBox(height: 16),
            CarbonTextInput(label: "Name", controller: nameController),
            const SizedBox(height: 12),
            CarbonTextInput(label: "Phone", controller: phoneController),
            const SizedBox(height: 12),
            CarbonTextInput(label: "Relation (optional)", controller: relationController),
            const SizedBox(height: 20),
            CarbonButton(
              label: "Save",
              alignment: MainAxisAlignment.center,
              onPressed: () {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (saved == true) {
      await DatabaseManager().insertEmergencyTarget(
        id: uuid.v4(),
        patientUuid: widget.patient.patientUuid,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        relation: relationController.text.trim().isEmpty ? null : relationController.text.trim(),
      );
      await _load();
    }
  }

  Future<void> _removeTarget(EmergencyTarget target) async {
    await DatabaseManager().deleteEmergencyTarget(target.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wearable Settings")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("PAIRING", style: CarbonTheme.carbonLabelTextStyle),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _paired,
                  onChanged: _togglePairing,
                  title: const Text("Wearable Paired"),
                  subtitle: Text(_paired ? "Orders and alerts below will sync to it." : "No wearable connected yet."),
                ),
                if (_paired) ...[
                  const SizedBox(height: 8),
                  CarbonTextInput(label: "Device Name", controller: _deviceNameController, onChanged: (_) => _saveDeviceName()),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text("DOCTOR'S ORDERS TO SYNC", style: CarbonTheme.carbonLabelTextStyle),
                const SizedBox(height: 4),
                Text("Choose which active orders should buzz your wearable as a reminder.", style: CarbonTheme.carbonHelperTextStyle),
                const SizedBox(height: 8),
                if (_orders.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("No active care orders yet.", style: TextStyle(color: Colors.grey)))
                else
                  ..._orders.map((order) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: order.wearableSyncEnabled,
                        onChanged: (v) => _toggleOrderSync(order, v),
                        title: Text(order.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: order.detail.isNotEmpty ? Text(order.detail) : null,
                      )),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text("PANIC BUTTON", style: CarbonTheme.carbonLabelTextStyle),
                const SizedBox(height: 4),
                Text("Choose what can trigger an emergency alert from the wearable.", style: CarbonTheme.carbonHelperTextStyle),
                const SizedBox(height: 8),
                ..._alerts.map((alert) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: alert.enabled,
                      onChanged: (v) => _toggleAlert(alert, v),
                      title: Text(alert.label),
                    )),
                const SizedBox(height: 16),
                Text("NOTIFY", style: CarbonTheme.carbonLabelTextStyle),
                const SizedBox(height: 4),
                Text("Everyone below is notified when any armed trigger fires.", style: CarbonTheme.carbonHelperTextStyle),
                const SizedBox(height: 8),
                ..._targets.map((target) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Symbols.emergency, color: Colors.redAccent),
                      title: Text(target.name),
                      subtitle: Text([target.phone, if (target.relation != null) target.relation!].join(' — ')),
                      trailing: IconButton(icon: const Icon(Symbols.delete_outline), onPressed: () => _removeTarget(target)),
                    )),
                const SizedBox(height: 8),
                CarbonButton(
                  label: "Add Emergency Contact",
                  icon: Symbols.person_add,
                  style: CarbonButtonStyle.secondary,
                  alignment: MainAxisAlignment.center,
                  onPressed: _addTarget,
                ),
              ],
            ),
    );
  }
}
