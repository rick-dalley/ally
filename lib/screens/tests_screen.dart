import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medical_test.dart';
import '../classes/patient.dart';
import '../classes/reminder_registry.dart';
import '../widgets/book_test_sheet.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import '../widgets/test_catalog_picker_sheet.dart';

class TestsScreen extends StatefulWidget {
  final Patient user;
  const TestsScreen({super.key, required this.user});

  @override
  State<StatefulWidget> createState() => TestsScreenState();
}

class TestsScreenState extends State<TestsScreen> {
  List<PatientTest> _tracked = [];
  bool _loadingTracked = true;

  @override
  void initState() {
    super.initState();
    _loadTracked();
  }

  Future<void> _loadTracked() async {
    final rows = await DatabaseManager().getPatientTests(widget.user.patientUuid);
    if (!mounted) return;
    setState(() {
      _tracked = rows.map((row) => PatientTest.fromRow(row)).toList();
      _loadingTracked = false;
    });
  }

  // Two-step: pick from the catalog (a scrollable list of icon tiles, not a dropdown),
  // then ask when to be reminded and any special instructions from the lab.
  Future<void> _startNewTest() async {
    final rows = await DatabaseManager().getTestCatalog();
    final catalog = rows.map((row) => TestCatalogEntry.fromRow(row)).toList();
    if (!mounted) return;

    final TestCatalogEntry? chosen = await showModalBottomSheet<TestCatalogEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => TestCatalogPickerSheet(catalog: catalog),
    );
    if (chosen == null || !mounted) return;

    // Reloads unconditionally once the booking sheet closes, regardless of how it
    // closed — dismissing by tapping the background pops with a null result, not
    // true, so gating the reload on the return value meant a background-dismiss after
    // a successful save would leave the new test invisible until the whole screen
    // was reopened.
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => BookTestSheet(patientUuid: widget.user.patientUuid, catalogEntry: chosen),
    );
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
          child: Text("Tests", style: CarbonTheme.carbonLabelTextStyle),
        ),
        backgroundColor: AppTheme.lightTheme.canvasColor,
      ),
      body: _loadingTracked
          ? const Center(child: CircularProgressIndicator())
          : _tracked.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "No tests scheduled yet. Tap + to schedule one.",
                  style: CarbonTheme.carbonHelperTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tracked.length,
              itemBuilder: (context, index) => _buildTrackedTile(_tracked[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewTest,
        child: const Icon(Symbols.add),
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
                Icon(test.icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test.name,
                    style: CarbonTheme.carbonLabelTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Last done: $lastDone", style: CarbonTheme.carbonHelperTextStyle),
            Text("Next due: $nextDue", style: CarbonTheme.carbonHelperTextStyle),
            if (test.notes != null && test.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Symbols.info, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(test.notes!, style: CarbonTheme.carbonHelperTextStyle)),
                ],
              ),
            ],
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
