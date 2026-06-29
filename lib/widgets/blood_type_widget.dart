import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.bloodtype_sharp, color: Colors.red),
          const Text("Blood Type", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDropdown(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildRhDropdown(context)),
            ],
          ),
          SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text("Save"),
              // M3-compliant styling for better accessibility and touch targets
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48), // Ensures a standard touch-friendly height
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<AboType>(
      decoration: const InputDecoration(
        labelText: "ABO Group",
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFFF4F4F4), // Carbon 'ui-01' grey
      ),
      initialValue: selectedAbo,
      onChanged: onAboChanged,
      items: AboType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
    );
  }

  Widget _buildRhDropdown(BuildContext context) {
    return DropdownButtonFormField<RhFactor>(
      decoration: const InputDecoration(
        labelText: "Rh Factor",
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFFF4F4F4),
      ),
      initialValue: selectedRh,
      onChanged: onRhChanged,
      items: RhFactor.values.map((factor) => DropdownMenuItem(value: factor, child: Text(factor.label))).toList(),
    );
  }
}

class BloodTypeTile extends StatelessWidget {
  final BloodType bloodType;
  final VoidCallback onTap;

  const BloodTypeTile({super.key, required this.bloodType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4), // Carbon 'ui-01'
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.bloodtype, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "BLOOD TYPE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF525252), // Carbon 'text-02'
                    letterSpacing: 0.5,
                  ),
                ),
                Text(bloodType.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
