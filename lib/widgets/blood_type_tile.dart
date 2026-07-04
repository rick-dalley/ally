import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../classes/blood_type.dart';

class BloodTypeTile extends StatelessWidget {
  final BloodType bloodType;
  final VoidCallback onTap;

  const BloodTypeTile({super.key, required this.bloodType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Now the column shrinks to fit content
              children: [
                Text(
                  "BLOOD TYPE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF525252),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(bloodType.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 12), // Gap between text and icon
            Icon(Symbols.bloodtype, color: Colors.red, size: 24),
          ],
        ),
      ),
    );
  }
}
