import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/carbon_style_constants.dart';
import '../classes/medication_services.dart';
import '../widgets/carbon_style_selection_tile.dart';

class GetMedicationType extends StatefulWidget {
  final Function(MedicationTypes) onTypeSelected;

  const GetMedicationType({super.key, required this.onTypeSelected});

  @override
  State<GetMedicationType> createState() => _GetMedicationTypeState();
}

class _GetMedicationTypeState extends State<GetMedicationType> {
  MedicationTypes? _selectedType;

  // Helper to format enum values into display strings
  String _formatType(MedicationTypes type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: EdgeInsets.all(CarbonSpacing.wide.width),
        itemCount: MedicationTypes.values.length,
        separatorBuilder: (_, _) => SizedBox(height: CarbonSpacing.narrow.width),
        itemBuilder: (context, index) {
          final type = MedicationTypes.values[index];

          return CarbonSelectionTile(
            title: _formatType(type),
            // Optionally add an icon based on type here
            onTap: () {
              setState(() => _selectedType = type);
              widget.onTypeSelected(type);
            },
            // Logic to show a selected state if you have that capability in CarbonActionTile
            // If CarbonActionTile doesn't handle "selected", you could wrap it in a Container
          );
        },
      ),
    );
  }
}
