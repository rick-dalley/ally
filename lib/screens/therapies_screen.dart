import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/colors/domain_colors.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'add_therapy_screen.dart';

// Home for every care_order — doctor-ordered (arrived via Progressor's discharge
// handoff, source: 'Imported care plan') and self-directed (added right here, source:
// 'Self-directed') shown side by side, since both are the same underlying record.
// Opening this screen marks everything viewed, clearing the profile tile's dot.
class TherapiesScreen extends StatefulWidget {
  final Patient patient;

  const TherapiesScreen({super.key, required this.patient});

  @override
  State<TherapiesScreen> createState() => _TherapiesScreenState();
}

class _TherapiesScreenState extends State<TherapiesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _therapies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await DatabaseManager().markTherapiesViewed(widget.patient.patientUuid);
    final rows = await DatabaseManager().getCareOrdersForPatient(widget.patient.patientUuid);
    if (!mounted) return;
    setState(() {
      _therapies = rows;
      _loading = false;
    });
  }

  Future<void> _addTherapy() async {
    final bool? added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddTherapyScreen(patient: widget.patient)),
    );
    if (added == true) _load();
  }

  Future<void> _confirmDiscontinue(Map<String, dynamic> therapy) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Discontinue ${therapy['label']}?"),
        content: const Text("This stops it from showing up as due or reminding you — it stays in your history."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Discontinue")),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseManager().discontinueCareOrder(therapy['id'] as String);
      _load();
    }
  }

  bool _isDoctorOrdered(Map<String, dynamic> therapy) => (therapy['source'] as String?) == 'Imported care plan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Therapies", style: CarbonTheme.carbonLabelTextStyle),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _therapies.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Nothing here yet — add a therapy below, or one will show up here automatically if your doctor sends one.",
                  textAlign: TextAlign.center,
                  style: CarbonTheme.carbonTextStyle,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final therapy in _therapies)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Symbols.physical_therapy, color: AppDomain.therapies.color),
                      title: Text(therapy['label'] as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((therapy['directions'] as String?)?.isNotEmpty ?? false)
                            Text(therapy['directions'] as String),
                          if ((therapy['frequency'] as String?)?.isNotEmpty ?? false)
                            Text(therapy['frequency'] as String, style: CarbonTheme.carbonHintTextStyle),
                          Text(
                            _isDoctorOrdered(therapy) ? "Doctor-ordered" : "Self-directed",
                            style: CarbonTheme.carbonHintTextStyle?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Symbols.close),
                        tooltip: "Discontinue",
                        onPressed: () => _confirmDiscontinue(therapy),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CarbonCompactButton(
            icon: Symbols.add,
            label: "Add a Therapy",
            style: CarbonButtonStyle.primary,
            onTap: _addTherapy,
          ),
        ),
      ),
    );
  }
}
