import 'package:flutter/material.dart';

import '../classes/archived/carbon_color_constants_old.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/patient.dart';

class CarbonAvatar extends StatelessWidget {
  final Patient user;

  const CarbonAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final assetPath = "assets/images/faces/users/${user.name}.png";

    return Container(
      width: CarbonIcons.extraExtraLarge.size.width,
      height: CarbonIcons.extraExtraLarge.size.height,
      decoration: BoxDecoration(
        color: carbonColorPrimary04,
        shape: BoxShape.circle,
        border: Border.all(color: carbonColorBorderSubtle01, width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // This only runs if the PNG asset doesn't exist or fails to load
            return Container(
              color: carbonColorPrimary04,
              alignment: Alignment.center,
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: CarbonTheme.carbonTextStyle),
            );
          },
        ),
      ),
    );
  }
}
