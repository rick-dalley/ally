import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../classes/carbon_color_constants.dart';

class CarbonSeparator extends StatelessWidget {
  const CarbonSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: carbonColorSeparator);
  }
}

class CarbonVerticalSeparator extends StatelessWidget {
  double? width;
  double? height;
  CarbonVerticalSeparator({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: width ?? 1.0, // Thickness
        height: height ?? 40, // Fixed height to make it shorter than the tile
        color: carbonColorSeparator, // Your preferred divider color
      ),
    );
  }
}
