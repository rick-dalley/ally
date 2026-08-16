import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/medical_category_colors.dart';
import '../classes/patient_condition.dart';
import '../widgets/condition_chip.dart';
import '../widgets/carbon_quick_entry_field.dart';
import '../widgets/halo_ripple_chip.dart';

// categoryIcons now lives in medical_category_colors.dart as medicalCategoryColors —
// kept as a local alias so this screen's many existing references don't all need
// renaming for what's purely a "moved to a shared file" change.
Map<String, MedicalCategory> get categoryIcons => medicalCategoryColors;

class ExistingMedicalConditionsScreen extends StatefulWidget {
  final String patientUuid;
  final ScrollController scrollController;

  const ExistingMedicalConditionsScreen({
    super.key,
    required this.patientUuid,
    required this.scrollController,
  });

  @override
  State<ExistingMedicalConditionsScreen> createState() =>
      ExistingMedicalConditionsScreenState();
}

class ExistingMedicalConditionsScreenState
    extends State<ExistingMedicalConditionsScreen> {
  late Future<Map<String, List<ConditionReference>>> _catalogFuture;
  late Future<List<PatientCondition>> _patientConditions;

  // We will store a flat list of references once loaded to quickly render the top dock
  List<ConditionReference> _allConditionsFlat = [];

  @override
  void initState() {
    super.initState();
    _patientConditions = DatabaseManager().getConditionsForPatient(
      widget.patientUuid,
    );
    _loadCatalog();
  }

  void _loadCatalog() {
    _catalogFuture = DatabaseManager().getConditionsCatalog().then((data) {
      // Flatten the incoming catalog map data structure for fast summary lookups
      setState(() {
        _allConditionsFlat = data.values.expand((list) => list).toList();
      });
      return data;
    });
  }

  // A condition the patient typed rather than picked from the catalog — filed under
  // "Custom" so it gets a chip and full status/onset/duration editing exactly like a
  // catalog pick, instead of sitting inert in a notes field nobody reads back.
  Future<void> _addCustomCondition(String name) async {
    final int conditionId = await DatabaseManager().getOrCreateCustomCondition(
      name,
    );
    await DatabaseManager().insertPatientCondition(
      PatientCondition(
        patientUuid: widget.patientUuid,
        conditionId: conditionId,
        name: name,
        status: ConditionStatus.active,
        onset: DateTime.now(),
      ),
    );
    setState(() {
      _patientConditions = DatabaseManager().getConditionsForPatient(
        widget.patientUuid,
      );
    });
    _loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PatientCondition>>(
      future: _patientConditions,
      builder: (context, patientSnapshot) {
        // 1. Unpack our live database conditions (default to an empty list while waiting)
        final List<PatientCondition> livePatientConditions =
            patientSnapshot.data ?? [];

        // Calculate active condition status cleanly based on our unpacked database records
        final bool hasActiveConditions = livePatientConditions.isNotEmpty;

        return Column(
          children: [
            // Title bar block
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "KNOWN MEDICAL CONDITIONS",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            //Anchored Active Conditions Top Panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: !hasActiveConditions
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !hasActiveConditions
                    ? Colors.transparent
                    : carbonColorField,
                borderRadius: BorderRadius.zero,
                border: !hasActiveConditions
                    ? null
                    : Border.all(color: carbonColorBorderStrong01, width: 1),
              ),
              child: !hasActiveConditions
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assignment_late_outlined,
                              size: 16,
                              color: AppTheme.onPrimaryColor,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Conditions that are currently diagnosed",
                              style: CarbonTheme.carbonTextStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: livePatientConditions.map((
                            PatientCondition currentCondition,
                          ) {
                            // Find the matching master reference metadata in memory for this row
                            final selectedCurrentRef = _allConditionsFlat
                                .firstWhere(
                                  (ref) =>
                                      ref.id == currentCondition.conditionId,
                                  orElse: () => ConditionReference(
                                    id: currentCondition.conditionId,
                                    name: currentCondition.name,
                                    category: "",
                                  ),
                                );
                            currentCondition.name = selectedCurrentRef.name;
                            return ConditionChip(
                              patientUuid: widget.patientUuid,
                              icon: categoryIcons[selectedCurrentRef.category]!
                                  .iconData,
                              color: categoryIcons[selectedCurrentRef.category]!
                                  .color,
                              patientCondition: currentCondition,
                              onDeleteCondition: (int id) async {
                                await DatabaseManager().deletePatientCondition(
                                  id,
                                );
                                setState(() {
                                  _patientConditions = DatabaseManager()
                                      .getConditionsForPatient(
                                        widget.patientUuid,
                                      );
                                });
                              },
                              onUpdateCondition: () {
                                // When a chip updates, trigger the exact same parent refresh query!
                                setState(() {
                                  _patientConditions = DatabaseManager()
                                      .getConditionsForPatient(
                                        widget.patientUuid,
                                      );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),

            // The main scrollable data input catalog
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  CarbonQuickEntryField(
                    label: "Don't see it below?",
                    hintText: "Type a condition and tap the check to add it",
                    onSave: _addCustomCondition,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Tap and the conditions below that you currently have, or which you previously experienced.",
                    style: CarbonTheme.carbonHelperTextStyle,
                  ),
                  const SizedBox(height: 14),

                  FutureBuilder<Map<String, List<ConditionReference>>>(
                    future: _catalogFuture,
                    builder: (context, catalogSnapshot) {
                      if (catalogSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (catalogSnapshot.hasError ||
                          !catalogSnapshot.hasData) {
                        return const Text(
                          "Failed to load clinical conditions catalog from disk.",
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      final catalogMap = catalogSnapshot.data!;

                      return Container(
                        width: double.infinity,
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Pass down livePatientConditions so your individual sub-group chips know their selection state synchronously
                          children: catalogMap.entries
                              .map(
                                (group) => _buildGroup(
                                  group.key,
                                  group.value,
                                  livePatientConditions,
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Anchored bottom control panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor,
                border: Border(
                  top: BorderSide(color: AppTheme.tertiaryColor, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saveAssessment,
                    child: Text(
                      "DONE",
                      style: CarbonTheme.carbonPrimaryButtonTextStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroup(
    String category,
    List<ConditionReference> conditions,
    List<PatientCondition> liveRecords,
  ) {
    MedicalCategory categoryIcon = categoryIcons[category]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // HaloRippleChip's own Row has a Flexible(Text) inside it (so a long
            // category name wraps instead of overflowing) — Flexible needs bounded
            // width from its immediate parent Row, but a non-flex child of a Row gets
            // unbounded main-axis constraints by design. Expanded here is what
            // actually supplies the bounded width HaloRippleChip's Flexible depends
            // on; without it this throws "RenderFlex children have non-zero flex but
            // incoming width constraints are unbounded" the instant this renders.
            Expanded(
              child: HaloRippleChip(
                iconData: categoryIcon.iconData,
                text: category,
                color: categoryIcon.color,
                backgroundColor: Color(0xFF000000),
                animate: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((condition) {
            // Check selection instantly against our active database row cache
            final bool isSelected = liveRecords.any(
              (pc) => pc.conditionId == condition.id,
            );

            return FilterChip(
              label: Text(condition.name),
              // 1. Customize the Text Style and Font Color
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.onPrimaryColor
                    : categoryIcon.color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              // 2. Customize the Border Color and Thickness
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : categoryIcon.color.withAlpha(128),
                width: 1.5,
              ),
              // 3. Customize Background Fill dynamically to match
              color: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return categoryIcon.color; // Solid category color when active
                }
                return categoryIcon.color.withAlpha(
                  20,
                ); // Soft tint when inactive
              }),
              selected: isSelected,
              onSelected: (bool selected) async {
                if (selected) {
                  final newIncomplete = PatientCondition.fromCondition(
                    widget.patientUuid,
                    condition,
                  );
                  await DatabaseManager().insertPatientCondition(newIncomplete);
                } else {
                  final recordToRemove = liveRecords.firstWhere(
                    (pc) => pc.conditionId == condition.id,
                  );
                  if (recordToRemove.id != null) {
                    await DatabaseManager().deletePatientCondition(
                      recordToRemove.id!,
                    );
                  }
                }

                // Re-read from SQLite and trigger UI sync
                setState(() {
                  _patientConditions = DatabaseManager()
                      .getConditionsForPatient(widget.patientUuid);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void saveAssessment() async {
    // Your _selectedConditions set continues to hold structural SQLite row IDs cleanly
    Navigator.pop(context);
  }
}
