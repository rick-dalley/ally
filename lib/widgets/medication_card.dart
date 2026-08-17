import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:triage/classes/database_manager.dart';

import '../classes/allergen.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/medication_services.dart';
import '../classes/tablet.dart';
import 'allergy_conflict_chip.dart';
import 'change_medication_sheet.dart';
import 'interaction_chip.dart';

class MedicationCard extends StatefulWidget {
  final Medication medication;
  final List<InteractionConflict> interactions;
  final List<AllergyConflict> allergyConflicts;
  final Set<String> acknowledgedInteractionPairs;
  final Set<String> dismissedInteractionPairs;
  final Future<void> Function(String medicationA, String medicationB) onAcknowledgeInteraction;
  final Future<void> Function(String medicationA, String medicationB) onDismissInteraction;
  // Archives the medication (stops tracking it as active) rather than deleting its
  // history — the patient may go back on it later, and past dosing matters for the
  // therapy-impact timeline.
  final VoidCallback onArchive;
  // Called after a dosage/frequency change is saved, so the parent can reload — the
  // card doesn't own the source-of-truth list, so it can't refresh itself.
  final VoidCallback? onMedicationChanged;
  final ValueChanged<bool>? onExpansionChanged;
  final int? index;
  const MedicationCard({
    super.key,
    required this.medication,
    required this.interactions,
    this.allergyConflicts = const [],
    required this.onArchive,
    required this.acknowledgedInteractionPairs,
    required this.dismissedInteractionPairs,
    required this.onAcknowledgeInteraction,
    required this.onDismissInteraction,
    this.onMedicationChanged,
    this.index,
    this.onExpansionChanged,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  Map<String, dynamic>? _datasheet;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    // If we already know the datasheet is local, get it immediately. Deferred to after
    // the current frame — triggerFetch's setState(_isFetching = true) runs before its
    // first await, and calling it synchronously from initState throws "setState called
    // during build" (same pattern hit and fixed elsewhere in the wizard/reminders code).
    if (widget.medication.hasLocalDataSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          triggerFetch(
            medicationId: widget.medication.id,
            setId: widget.medication.setId!,
            medicationName: widget.medication.name,
          );
        }
      });
    }
  }

  Future<void> _openChangeSheet(BuildContext context) async {
    final bool? changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => ChangeMedicationSheet(medication: widget.medication),
    );
    if (changed == true) {
      widget.onMedicationChanged?.call();
    }
  }

  void triggerFetch({required String medicationName, required String setId, required String medicationId}) async {
    if (_isFetching) return;

    setState(() => _isFetching = true);
    final interactions = await DatabaseManager().getAllInteractionsForDrug(medicationName);

    final row = await MedicationService.getDrugDataSheet(medicationId, medicationName, setId);

    if (mounted) {
      setState(() {
        _datasheet = row; // This is our in-memory "Source of Truth"
        if (interactions.isNotEmpty) {
          _datasheet ??= {};
          _datasheet!['interactions'] = interactions;
        }
        _isFetching = false;

        // Update the map immediately here if you want,
        // but only if the row actually came back with data.
        if (row != null) {
          widget.medication.hasLocalDataSheet;
          widget.medication.setId = row['set_id'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String medicationId = widget.medication.id;
    final String medicationName = widget.medication.name;
    // The raw value actually stored on the medication (a latin phrase or "PRN", not a
    // FrequencyCodes short code), so it's displayed as-is rather than run through the
    // code-lookup table.
    final String frequency = widget.medication.freq ?? '';
    final List<InteractionConflict> medicationInteractions = widget.interactions
        .where((conflict) => conflict.hasInteraction(medicationName))
        .toList();
    final List<AllergyConflict> medicationAllergyConflicts = widget.allergyConflicts
        .where((conflict) => conflict.matchesMedication(medicationName))
        .toList();
    final TabletShapes shape = widget.medication.shape ?? TabletShapes.round;
    final TabletColors color = widget.medication.color ?? TabletColors.white;

    return Card(
      margin: const EdgeInsets.all(8),
      shape: Border.all(color: carbonColorBorderSubtle00),
      shadowColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Icon (Direct child of Row)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: SvgPicture.asset(
                'assets/images/pills/${shape.svg}',
                width: 40,
                height: 40,
                colorMapper: PillColorMapper(color.color),
              ),
            ),
          ),

          // 2. Expanded (Direct child of Row - no Padding parent)
          Expanded(
            child: Column(
              children: [
                // Row: Name + Delete
                Row(
                  children: [
                    // Corrected: Padding moved INSIDE Expanded
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                        child: Text(medicationName.toUpperCase(), style: CarbonTheme.carbonTertiaryButtonTextStyle),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openChangeSheet(context),
                      icon: const Icon(Symbols.edit),
                      tooltip: "Change dosage or frequency",
                    ),
                    IconButton(
                      onPressed: widget.onArchive,
                      icon: const Icon(Symbols.close),
                      tooltip: "Stop taking this medication",
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                    child: Text(
                      "Dose: ${widget.medication.dose ?? 'N/A'} —  $frequency",
                      style: CarbonTheme.carbonHintTextStyle,
                    ),
                  ),
                ),
                if (medicationInteractions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: InteractionsChip(
                      medicationName: medicationName,
                      interactions: medicationInteractions,
                      acknowledgedPairs: widget.acknowledgedInteractionPairs,
                      dismissedPairs: widget.dismissedInteractionPairs,
                      onAcknowledge: widget.onAcknowledgeInteraction,
                      onDismiss: widget.onDismissInteraction,
                    ),
                  ),
                if (medicationAllergyConflicts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: AllergyConflictChip(medicationName: medicationName, conflicts: medicationAllergyConflicts),
                  ),
                // ExpansionTile
                ExpansionTile(
                  key: ValueKey("tile_$medicationId"),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text("Data Sheet...", style: CarbonTheme.carbonLabelTextStyle),
                  trailing: const Icon(Icons.expand_more),
                  onExpansionChanged: (expanded) {
                    if (expanded && _datasheet == null) {
                      triggerFetch(
                        medicationId: widget.medication.id,
                        medicationName: widget.medication.name,
                        setId: widget.medication.setId!,
                      );
                    }
                    widget.onExpansionChanged?.call(expanded);
                  },
                  children: [
                    if (_isFetching)
                      const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
                    else if (_datasheet != null && _datasheet!.isNotEmpty) ...[
                      ClassChips(dataSheet: _datasheet),
                      ...fdaSections(),
                    ] else
                      const ListTile(title: Text("No datasheet details found.")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> fdaSections() {
    if (_datasheet == null) return [];

    Map<String, dynamic> targetJson = _datasheet!;
    if (_datasheet!.containsKey('results') && _datasheet!['results'] is List) {
      targetJson = _datasheet!['results'][0];
    }

    final Map<String, String> sectionMap = {
      'indications_and_usage': 'Indications',
      'interactions': 'All Interactions',
      'dosage_and_administration': 'Dosage',
      'warnings_and_cautions': 'Warnings',
      'adverse_reactions': 'Adverse Reactions',
      'description': 'Description',
    };

    return sectionMap.entries.map((entry) {
      final data = targetJson[entry.key];
      String text = data?.toString() ?? "";
      List<Widget> children = [];
      if (text.isEmpty || text == "null") return const SizedBox.shrink();
      if (entry.key == "interactions") {
        for (dynamic interaction in data) {
          children.add(
            InteractionTile(interactsWith: interaction['interacting_drug'], explanation: interaction['explanation']),
          );
        }
      } else {
        children = [Padding(padding: const EdgeInsets.all(16.0), child: SelectableText(text))];
      }

      return ExpansionTile(
        shape: const Border(),
        // Remove the top and bottom borders when collapsed"
        collapsedShape: const Border(),
        // Keep it explicit and simple to avoid the 'bool vs double' theme leak
        title: Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        children: children,
      );
    }).toList();
  }
}

class ClassChips extends StatelessWidget {
  final Map<String, dynamic>? dataSheet;
  const ClassChips({super.key, required this.dataSheet});

  @override
  Widget build(BuildContext context) {
    final String classesRaw = dataSheet!['classes']?.toString() ?? "";
    if (classesRaw.isEmpty) return const SizedBox.shrink();

    final List<String> classList = classesRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (classList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: classList
            .map(
              (tagName) => Chip(
                label: Text(tagName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.blue.shade50,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: Colors.blue.shade100),
              ),
            )
            .toList(),
      ),
    );
  }
}
