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
