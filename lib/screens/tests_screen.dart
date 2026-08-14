import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/listable.dart';
import '../classes/medical_test.dart';
import '../classes/patient.dart';
import '../classes/reminder_registry.dart';
import '../widgets/carbon_button_compact.dart';
import '../widgets/carbon_style_dropdown.dart';

class TestsScreen extends StatefulWidget {
  final Patient user;
  const TestsScreen({super.key, required this.user});

  @override
  State<StatefulWidget> createState() => TestsScreenState();
}

class TestsScreenState extends State<TestsScreen> {
  late Future<List<TestCatalogEntry>> _catalogFuture;
  List<PatientTest> _tracked = [];
  TestCatalogEntry? _selectedCatalogEntry;
  bool _loadingTracked = true;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
    _loadTracked();
  }

  Future<List<TestCatalogEntry>> _loadCatalog() async {
    final rows = await DatabaseManager().getTestCatalog();
    return rows.map((row) => TestCatalogEntry.fromRow(row)).toList();
  }

  Future<void> _loadTracked() async {
    final rows = await DatabaseManager().getPatientTests(widget.user.patientUuid);
    if (!mounted) return;
    setState(() {
      _tracked = rows.map((row) => PatientTest.fromRow(row)).toList();
      _loadingTracked = false;
    });
  }

  Future<void> _addTrackedTest(TestCatalogEntry entry) async {
    await DatabaseManager().addPatientTest(widget.user.patientUuid, {
      'name': entry.name,
      'location': entry.location.name,
      'last_done': null,
      'next_due': null,
      'notes': null,
    });
    await _loadTracked();
  }

  Future<void> _pickNextDue(PatientTest test) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: test.nextDue ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null || test.id == null) return;
    await DatabaseManager().rescheduleTestReminder(test.id!, picked);
    await ReminderRegistry.instance.refresh();
    await _loadTracked();
  }

  Future<void> _markDone(PatientTest test) async {
    if (test.id == null) return;
    await DatabaseManager().markTestDone(test.id!, DateTime.now());
    await ReminderRegistry.instance.refresh();
    await _loadTracked();
  }

  Future<void> _remove(PatientTest test) async {
    if (test.id == null) return;
    await DatabaseManager().deletePatientTest(test.id!);
    await ReminderRegistry.instance.refresh();
    await _loadTracked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: AlignmentGeometry.centerLeft,
          child: Text(
            "Tests",
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.w400),
          ),
        ),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Tracked Tests", style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 8),
          if (_loadingTracked)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator())
          else if (_tracked.isEmpty)
            Text("Nothing tracked yet — add one below.", style: CarbonTheme.carbonHelperTextStyle)
          else
            ..._tracked.map(_buildTrackedTile),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text("Add a Test to Track", style: CarbonTheme.carbonHeadingTextStyle),
          const SizedBox(height: 8),
          Text(
            "Common tests to start from — not every test that exists, just a starting list.",
            style: CarbonTheme.carbonHintTextStyle,
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<TestCatalogEntry>>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              final catalog = snapshot.data ?? const [];
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator());
              }
              if (catalog.isEmpty) {
                return Text("No test catalog loaded.", style: CarbonTheme.carbonHelperTextStyle);
              }
              final TestCatalogEntry effective = _selectedCatalogEntry ?? catalog.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarbonDropdown<TestCatalogEntry>(
                    label: "Choose a test",
                    placeholder: "Choose a test",
                    helperText: "${effective.location.label}${effective.category != null ? ' • ${effective.category}' : ''}",
                    items: catalog,
                    value: effective,
                    onChanged: (Listable val) {
                      setState(() => _selectedCatalogEntry = val as TestCatalogEntry);
                    },
                  ),
                  const SizedBox(height: 12),
                  CarbonCompactButton(
                    icon: Symbols.add,
                    label: "Add to Tracked Tests",
                    style: CarbonButtonStyle.primary,
                    onTap: () => _addTrackedTest(effective),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackedTile(PatientTest test) {
    final String lastDone = test.lastDone != null ? _formatDate(test.lastDone!) : "Never done";
    final String nextDue = test.nextDue != null ? _formatDate(test.nextDue!) : "No reminder set";
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(test.location == TestLocation.home ? Symbols.home_health : Symbols.biotech, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test.name,
                    style: CarbonTheme.carbonLabelTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(test.location.label, style: CarbonTheme.carbonHelperTextStyle),
              ],
            ),
            const SizedBox(height: 4),
            Text("Last done: $lastDone", style: CarbonTheme.carbonHelperTextStyle),
            Text("Next due: $nextDue", style: CarbonTheme.carbonHelperTextStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                CarbonCompactButton(
                  icon: Symbols.check,
                  label: "Mark Done",
                  style: CarbonButtonStyle.secondary,
                  onTap: () => _markDone(test),
                ),
                CarbonCompactButton(
                  icon: Symbols.schedule,
                  label: "Set Reminder",
                  style: CarbonButtonStyle.secondary,
                  onTap: () => _pickNextDue(test),
                ),
                CarbonCompactButton(
                  icon: Symbols.close,
                  label: "Remove",
                  style: CarbonButtonStyle.ghost,
                  onTap: () => _remove(test),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
