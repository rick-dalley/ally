import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/database_manager.dart';

import '../classes/carbon_theme_constants.dart';
import '../classes/frequency_codes.dart';
import '../classes/medication_services.dart';
import '../classes/tablet.dart';
import 'interaction_chip.dart';

class MedicationCard extends StatefulWidget {
  final Medication medication;
  final List<InteractionConflict> interactions;
  final VoidCallback onDelete;
  final ValueChanged<bool>? onExpansionChanged;
  final int? index;
  const MedicationCard({
    super.key,
    required this.medication,
    required this.interactions,
    required this.onDelete,
    this.index,
    this.onExpansionChanged,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  Map<String, dynamic>? _datasheet;
  bool _isFetching = false;
  TabletShapes shape = TabletShapes.round;

  @override
  void initState() {
    super.initState();
    shape = widget.index != null ? TabletShapes.values[widget.index!] : TabletShapes.round;
    // If we already know the datasheet is local, get it immediately
    if (widget.medication.hasLocalDataSheet) {
      triggerFetch(
        medicationId: widget.medication.id,
        setId: widget.medication.setId!,
        medicationName: widget.medication.name,
      );
    }
  }

  void triggerFetch({required String medicationName, required String setId, required String medicationId}) async {
    if (_isFetching) return;

    setState(() => _isFetching = true);
    final interactions = await DatabaseManager().getAllInteractionsForDrug(medicationName);

    for (dynamic interaction in interactions) {}
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
    final Frequency? frequencyDetails = widget.medication.frequency;
    final String frequency = frequencyDetails != null
        ? FrequencyCodes.getFrequencyLabel(frequencyDetails.latinRecurrence!)
        : '';
    final List<InteractionConflict> medicationInteractions = widget.interactions
        .where((conflict) => conflict.hasInteraction(medicationName))
        .toList();

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
                colorMapper: PillColorMapper(TabletColors.values[widget.index! % 10].color),
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
                    IconButton(onPressed: widget.onDelete, icon: const Icon(Symbols.close)),
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
                    child: InteractionsChip(medicationName: medicationName, interactions: medicationInteractions),
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
