import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/avatar_action_widget.dart';
import '../app_theme.dart';
import '../classes/patient.dart';

class AddPatientsWheel extends StatefulWidget {
  final List<Patient> familyMembers;
  final VoidCallback onDismiss;
  final Function(int) onUserSelected;
  final VoidCallback onAddMember;

  const AddPatientsWheel({
    super.key,
    required this.familyMembers,
    required this.onDismiss,
    required this.onUserSelected,
    required this.onAddMember,
  });

  @override
  AddPatientsWheelState createState() => AddPatientsWheelState();
}

class AddPatientsWheelState extends State<AddPatientsWheel> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Blur Layer
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: AppColors.grey.all[0].withValues(alpha: 0.2)),
        ),

        // 2. The Close Button (The X)
        Positioned(
          top: 50,
          right: 20,
          child: IconButton(
            icon: Icon(Icons.close, size: 40, color: AppColors.grey.all[0]),
            onPressed: widget.onDismiss,
          ),
        ),

        // 3. The Responsive Content Area
        Center(child: _buildLayoutBasedOnCount()),
      ],
    );
  }

  Widget _buildLayoutBasedOnCount() {
    int count = widget.familyMembers.length;

    if (count == 1) {
      return Column(
        children: [
          AvatarActionWidget(
            label: widget.familyMembers[0].firstName,
            value: widget.familyMembers[0].patientUuid,
            onTap: (dynamic p1) {},
          ),
          Text("Add a Family Member to Track", style: TextStyle(color: AppColors.grey.all[0])),
          AvatarActionWidget(
            onTap: (int p1) {
              launchAddMember();
            },
            avatar: Icon(Symbols.plus_one),
          ),
        ],
      );
    } else if (count == 2) {
      final avatarWidget1 = widget.familyMembers[0].hasCustomAvatar
          ? ClipOval(
              child: Image.asset("assets/images/faces/users/${widget.familyMembers[0].name}.png", fit: BoxFit.cover),
            )
          : Text(
              widget.familyMembers[0].initials,
              style: TextStyle(color: AppColors.grey.all[0], fontWeight: FontWeight.bold),
            );
      final avatarWidget2 = widget.familyMembers[1].hasCustomAvatar
          ? ClipOval(
              child: Image.asset("assets/images/faces/users/${widget.familyMembers[1].name}.png", fit: BoxFit.cover),
            )
          : Text(
              widget.familyMembers[1].initials,
              style: TextStyle(color: AppColors.grey.all[0], fontWeight: FontWeight.bold),
            );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarActionWidget(
            label: widget.familyMembers[0].firstName,
            value: widget.familyMembers[0].patientUuid,
            onTap: (dynamic p1) {},
            avatar: avatarWidget1,
          ), // Helper to build existing avatars
          const SizedBox(width: 20),
          AvatarActionWidget(
            onTap: (int p1) {
              launchAddMember();
            },
            avatar: Icon(Symbols.plus_one),
          ),
          AvatarActionWidget(
            label: widget.familyMembers[1].firstName,
            value: widget.familyMembers[0].patientUuid,
            onTap: (dynamic p1) {},
            avatar: avatarWidget2,
          ),
        ],
      );
    } else {
      return buildRadialCircle(); // The full circle layout
    }
  }

  Widget buildRadialCircle() {
    List<Widget> items = [];
    int index = 0;
    // 1. Add your existing members as AvatarActionWidgets
    for (int i = 0; i < widget.familyMembers.length; i++) {
      final user = widget.familyMembers[i];

      // Logic: Check if image exists (you might need a helper method here)
      // For now, let's pass a Widget directly
      final avatarWidget = user.hasCustomAvatar
          ? ClipOval(child: Image.asset("assets/images/faces/users/${user.name}.png", fit: BoxFit.cover))
          : Text(
              user.initials,
              style: TextStyle(color: AppColors.grey.all[0], fontWeight: FontWeight.bold),
            );

      items.add(
        AvatarActionWidget(
          onTap: (val) => widget.onUserSelected(val), // Pass the user object, not index
          label: user.name,
          value: user.patientUuid, //changed value to dynamic to support using uuids
          avatar: avatarWidget, // Now this is a Widget
        ),
      );
    }
    return RadialCircleLayout(children: items);
  }

  void launchAddMember() {}
}

class RadialCircleLayout extends StatelessWidget {
  final List<Widget> children;
  final double radius;

  const RadialCircleLayout({super.key, required this.children, this.radius = 120.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(children.length, (index) {
            // Calculate angle: distribute items evenly around the circle
            final angle = (2 * pi / children.length) * index - (pi / 2);

            // Convert polar to cartesian coordinates
            final x = radius * cos(angle);
            final y = radius * sin(angle);

            return Transform.translate(offset: Offset(x, y), child: children[index]);
          }),
        );
      },
    );
  }
}

class DottedPlaceholder extends StatelessWidget {
  const DottedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey.all[0], width: 2, style: BorderStyle.solid),
        // Note: For a true dashed border, you'd use a CustomPainter,
        // but a simple dashed-looking border works well for UI.
      ),
      child: Icon(Icons.add, color: AppColors.grey.all[0]),
    );
  }
}
