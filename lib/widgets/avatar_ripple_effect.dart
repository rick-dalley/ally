import 'package:flutter/material.dart';

// A copy of HlcRippleEffect's animation shape (see high_low_close_capsule.dart), not a
// shared parameterization of it — that one is a small fixed-size out-of-range badge;
// this one needs to start at the avatar's own diameter and expand outward from its
// edge, a different enough shape that forcing one widget to cover both would mean
// threading avatar-sizing logic through code that has no other reason to know about
// avatars. A ring, not a filled circle — filled would just paint over the avatar
// rather than reading as a halo coming from its edge.
class AvatarRippleEffect extends StatefulWidget {
  final double
  size; // the avatar's own diameter — the ripple starts exactly here
  final Color color;

  const AvatarRippleEffect({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  State<AvatarRippleEffect> createState() => _AvatarRippleEffectState();
}

class _AvatarRippleEffectState extends State<AvatarRippleEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double progress = _controller.value;
        final double opacity = 1.0 - progress;
        // Grows from the avatar's own edge outward by up to 45% of its diameter.
        final double currentSize = widget.size * (1.0 + 0.45 * progress);
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.7 * opacity),
              width: 2.5,
            ),
          ),
        );
      },
    );
  }
}
