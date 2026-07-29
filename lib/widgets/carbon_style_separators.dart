import 'package:flutter/material.dart';

import '../classes/carbon_color_constants.dart';

class CarbonHorizontalSeparator extends StatelessWidget {
  const CarbonHorizontalSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: carbonColorSeparator);
  }
}

class CarbonVerticalSeparator extends StatelessWidget {
  final double? width;
  final double? height;
  const CarbonVerticalSeparator({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    double appliedWidth = width ?? 1.0;
    double appliedHeight = height ?? 4.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        width: appliedWidth, // Thickness
        height: appliedHeight, // Fixed height to make it shorter than the tile
        color: carbonColorVerticalSeparator, // Your preferred divider color
      ),
    );
  }
}
