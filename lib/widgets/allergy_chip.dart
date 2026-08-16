import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/allergen.dart';
import 'configure_allergy_dialog.dart';

// Mirrors ConditionChip exactly — a "collected" chip that fades to reflect its own
// state elsewhere would be tempting, but allergies don't have a status spectrum like
// conditions do (you either have it or you don't), so no fade treatment here.
class AllergyChip extends StatefulWidget {
  final IconData icon;
  final Color color;
  final PatientAllergy patientAllergy;
  final Function(int) onDeleteAllergy;
  final VoidCallback onUpdateAllergy;

  const AllergyChip({
    super.key,
    required this.icon,
    required this.color,
    required this.patientAllergy,
    required this.onDeleteAllergy,
    required this.onUpdateAllergy,
  });

  @override
  State<AllergyChip> createState() => AllergyChipState();
}

class AllergyChipState extends State<AllergyChip> {
  @override
  Widget build(BuildContext context) {
    return RawChip(
      avatar: Icon(widget.icon, size: 16, color: AppTheme.onPrimaryColor),
      label: Text(widget.patientAllergy.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      labelStyle: TextStyle(color: AppTheme.onPrimaryColor),
      backgroundColor: widget.color,
      deleteIcon: Icon(Icons.cancel, size: 14, color: AppTheme.onPrimaryColor),
      onDeleted: () {
        final int? id = widget.patientAllergy.id;
        if (id != null) widget.onDeleteAllergy(id);
      },
      onPressed: () => _showDetailsDialog(context),
    );
  }

  Future<void> _showDetailsDialog(BuildContext context) async {
    final wasUpdated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfigureAllergyDialog(patientAllergy: widget.patientAllergy),
    );
    if (wasUpdated == true) widget.onUpdateAllergy();
  }
}
