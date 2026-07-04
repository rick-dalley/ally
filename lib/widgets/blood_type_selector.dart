import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';

import '../classes/blood_type.dart';

class BloodTypeSelector extends StatelessWidget {
  final AboType? selectedAbo;
  final RhFactor? selectedRh;
  final ValueChanged<AboType?> onAboChanged;
  final ValueChanged<RhFactor?> onRhChanged;

  const BloodTypeSelector({
    super.key,
    required this.selectedAbo,
    required this.selectedRh,
    required this.onAboChanged,
    required this.onRhChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, right: 16, left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text("Blood Type", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20)),
              Spacer(),
              const Icon(Symbols.bloodtype_sharp, color: Colors.red),
            ],
          ),
          SizedBox(height: 8),
          Text("Select your blood type below. A blood type is a combination of ABO group and Rh factor (e.g., AB-)."),
          SizedBox(height: 16),
          _buildDropdown(context),
          const SizedBox(width: 16),
          _buildRhDropdown(context),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CarbonButton(
                  label: "Cancel",
                  isSecondary: true,
                  color: Colors.black26,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Expanded(
                child: CarbonButton(
                  label: "Save",
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return CarbonDropdown<AboType>(
      label: "ABO Group",
      items: AboType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
      onChanged: onAboChanged,
    );
  }

  Widget _buildRhDropdown(BuildContext context) {
    return CarbonDropdown<RhFactor>(
      label: "RH Factor",
      items: RhFactor.values.map((factor) => DropdownMenuItem(value: factor, child: Text(factor.label))).toList(),
      onChanged: onRhChanged,
    );
  }
}
