import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';
import '../classes/patient_condition.dart';
import 'condition_update.dart';

class ConditionChip extends StatefulWidget {
  final String patientUuid;
  final IconData icon;
  final Color color;
  final PatientCondition patientCondition;
  final Function(int) onDeleteCondition;
  final VoidCallback onUpdateCondition;

  const ConditionChip({
    super.key,
    required this.patientUuid,
    required this.icon,
    required this.color,
    required this.patientCondition,
    required this.onDeleteCondition,
    required this.onUpdateCondition,
  });

  @override
  State<ConditionChip> createState() => ConditionChipState();
}

class ConditionChipState extends State<ConditionChip> {
  @override
  Widget build(BuildContext context) {
    // In Remission / Recovered fade the chip out — still identifiable by color and
    // icon, but visually receding behind whatever's still Active. A faded fill reads
    // poorly under white icon/text though, so those switch to the solid category color
    // instead of staying white.
    final bool isResolved =
        widget.patientCondition.status != ConditionStatus.active;
    final Color contentColor = isResolved
        ? widget.color
        : AppTheme.onPrimaryColor;
    final bool hasReviewedTreatment =
        widget.patientCondition.treatmentReviewedAt != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RawChip(
          avatar: Icon(
            widget.icon, // Pass your Material Symbol or Icon here
            size: 16,
            color: contentColor,
          ),
          label: Text(
            widget.patientCondition.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          labelStyle: TextStyle(color: contentColor),
          backgroundColor: isResolved
              ? widget.color.withValues(alpha: 0.4)
              : widget.color,
          deleteIcon: Icon(Icons.cancel, size: 14, color: contentColor),
          onDeleted: () {
            int? id = widget.patientCondition.id;
            if (id != null) {
              widget.onDeleteCondition(id);
            }
          },
          onPressed: () {
            _showDetailsDialog(context);
          },
        ),
        // Marks "you've already told us how you're treating this" so it's obvious at a
        // glance which conditions still need a look and which to just come back to.
        if (hasReviewedTreatment)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(Symbols.task_alt, size: 14, color: widget.color),
            ),
          ),
      ],
    );
  }

  Future<void> _showDetailsDialog(BuildContext context) async {
    // 1. Notice we don't need 'notesController' here anymore!
    // Our new ConfigureConditionDialog handles its own controller inside its own initState.

    final wasUpdated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ConfigureConditionDialog(patientCondition: widget.patientCondition),
    );

    // 2. If the user hit 'Confirm' and saved changes to the DB:
    if (wasUpdated == true) {
      // Tell the parent screen to re-run its query and refresh the layout!
      widget.onUpdateCondition();
    }
  }
}
