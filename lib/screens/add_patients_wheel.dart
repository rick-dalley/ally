import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/patient.dart';

// Long-press on the top-corner avatar opens this: every current family member arranged
// in a circle, a round "+" centered inside the circle to add someone new, tap any
// avatar to jump straight to their data. Rewritten from scratch rather than patched
// again — the previous version appended the add-button into the same list the circular
// polar-math layout iterates over, so it became the Nth slice of the circle instead of
// a distinct centered element; the type declared on every onTap didn't match what was
// actually being passed (a patientUuid String coerced through a Function(int)), and the
// add-member layouts that existed only covered 1- and 2-person households, silently
// vanishing entirely for anyone with 3 or more family members.
class AddPatientsWheel extends StatelessWidget {
  final List<Patient> familyMembers;
  final VoidCallback onDismiss;
  final ValueChanged<String> onUserSelected; // patientUuid
  final VoidCallback onAddMember;

  const AddPatientsWheel({
    super.key,
    required this.familyMembers,
    required this.onDismiss,
    required this.onUserSelected,
    required this.onAddMember,
  });

  static const double _circleRadius = 110.0;
  static const double _avatarSize = 72.0;
  static const double _centerButtonSize = 64.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppTheme.surfaceColor.withValues(alpha: 0.2)),
          ),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: IconButton(
            icon: Icon(Icons.close, size: 40, color: AppTheme.onPrimaryColor),
            onPressed: onDismiss,
          ),
        ),
        Center(
          child: SizedBox(
            // Enough room for the circle's full diameter plus an avatar's own size at
            // the edge, so nothing clips even at the widest point.
            width: (_circleRadius * 2) + _avatarSize,
            height: (_circleRadius * 2) + _avatarSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < familyMembers.length; i++) _buildAvatar(familyMembers[i], i, familyMembers.length),
                // Deliberately the last child, outside the circle-position loop above —
                // an untranslated Stack child sits at dead center by construction,
                // which is what actually guarantees this is centered rather than
                // computed to merely look centered.
                _buildAddButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(Patient patient, int index, int total) {
    final double angle = (2 * pi / total) * index - (pi / 2);
    final double x = _circleRadius * cos(angle);
    final double y = _circleRadius * sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize + 24, // room for the label below the circle
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onUserSelected(patient.patientUuid),
              borderRadius: BorderRadius.circular(_avatarSize / 2),
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                child: ClipOval(child: _avatarContent(patient)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              patient.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.onPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarContent(Patient patient) {
    return Image.asset(
      "assets/images/faces/users/${patient.name}.png",
      fit: BoxFit.cover,
      // hasCustomAvatar is unconditionally true on Patient today, so this asset is
      // attempted for every patient regardless of whether the file actually exists —
      // true for the seeded demo patients, never true for a freshly-created one. A
      // broken-image exception here would take out the whole wheel, not just one
      // avatar, so this falls back to initials rather than assuming the asset exists.
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          patient.initials,
          style: TextStyle(color: AppTheme.onPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: onAddMember,
      borderRadius: BorderRadius.circular(_centerButtonSize / 2),
      child: Container(
        width: _centerButtonSize,
        height: _centerButtonSize,
        decoration: BoxDecoration(color: carbonColorButtonPrimary, shape: BoxShape.circle),
        child: Icon(Symbols.add, color: carbonColorButtonOnPrimary, size: 32),
      ),
    );
  }
}
