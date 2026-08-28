import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../classes/alertable.dart';
import '../classes/database_manager.dart';
import '../classes/emergency_target.dart';
import '../classes/patient.dart';

// What "dispatch" actually means here: neither iOS nor Android lets a third-party app
// place a call or send a text without the person in front of it confirming — there's
// no silent background send to build. So this is the real thing, not a placeholder:
// a full-screen alert with the trigger and one tap per emergency contact to call or
// text them, pushed the instant WearableSyncServer's onPanic fires (see main.dart).
class PanicAlertScreen extends StatefulWidget {
  final String patientUuid;
  final String triggerType;

  const PanicAlertScreen({super.key, required this.patientUuid, required this.triggerType});

  @override
  State<PanicAlertScreen> createState() => _PanicAlertScreenState();
}

class _PanicAlertScreenState extends State<PanicAlertScreen> {
  Patient? _patient;
  List<EmergencyTarget> _targets = [];
  bool _loading = true;

  AlertTrigger get _trigger {
    try {
      return AlertTrigger.values.byName(widget.triggerType);
    } catch (_) {
      return AlertTrigger.manual;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseManager();
    final List<Map<String, dynamic>> rows = await db.getPatientWithVitals(patientUuid: widget.patientUuid);
    final List<Map<String, dynamic>> targetRows = await db.getEmergencyTargetsForPatient(widget.patientUuid);
    if (!mounted) return;
    setState(() {
      _patient = rows.isEmpty ? null : Patient.fromJson(rows.first);
      _targets = targetRows.map(EmergencyTarget.fromRow).toList();
      _loading = false;
    });
  }

  Future<void> _call(EmergencyTarget target) async {
    final Uri uri = Uri(scheme: 'tel', path: target.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _text(EmergencyTarget target) async {
    final String name = _patient != null ? '${_patient!.firstName} ${_patient!.lastName}' : 'your contact';
    final Uri uri = Uri(scheme: 'sms', path: target.phone, queryParameters: {'body': '$name triggered a ${_trigger.defaultLabel.toLowerCase()} alert on their wearable.'});
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.red.shade700,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Symbols.emergency, color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _trigger.defaultLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _patient != null ? '${_patient!.firstName} ${_patient!.lastName}\'s wearable' : 'Wearable alert',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      if (_targets.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text("No emergency contacts configured yet.", style: TextStyle(color: Colors.white70)),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView(
                            children: _targets
                                .map(
                                  (target) => Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(target.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      subtitle: Text([target.phone, if (target.relation != null) target.relation!].join(' — ')),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Symbols.sms), onPressed: () => _text(target)),
                                          IconButton(icon: const Icon(Symbols.call), color: Colors.green, onPressed: () => _call(target)),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white), foregroundColor: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Dismiss"),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
