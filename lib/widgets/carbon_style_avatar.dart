import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../classes/archived/carbon_color_constants_old.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/patient.dart';

class CarbonAvatar extends StatelessWidget {
  final Patient user;

  const CarbonAvatar({super.key, required this.user});

  Widget _initials() {
    return Container(
      color: carbonColorPrimary04,
      alignment: Alignment.center,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        // carbonTextStyle defaults to the dark body-text color, illegible on this
        // circle's blue fill — needs the on-primary (white) color instead.
        style: CarbonTheme.carbonTextStyle?.copyWith(
          color: carbonColorButtonOnPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A real picked photo (AvatarPicker, from UserScreen) always wins over the old
    // demo asset-path convention — those bundled assets/images/faces/users/ photos
    // don't even ship anymore (see the asset-cleanup pass), so that path only ever
    // hits the initials fallback now unless a real avatar has been set.
    final Uint8List? avatar = user.avatar;
    final Widget image = avatar != null && avatar.isNotEmpty
        ? Image.memory(
            avatar,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _initials(),
          )
        : Image.asset(
            "assets/images/faces/users/${user.name}.png",
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _initials(),
          );

    return Container(
      width: CarbonIcons.extraExtraLarge.size.width,
      height: CarbonIcons.extraExtraLarge.size.height,
      decoration: BoxDecoration(
        color: carbonColorPrimary04,
        shape: BoxShape.circle,
        border: Border.all(color: carbonColorBorderSubtle01, width: 1.5),
      ),
      child: ClipOval(child: image),
    );
  }
}
