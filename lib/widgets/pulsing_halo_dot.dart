import 'package:flutter/material.dart';

// A small solid dot with a soft, breathing ring around it — used where a plain static
// dot (see the red "unseen" dots elsewhere on the profile screen) isn't loud enough on
// its own, e.g. a doctor's order landing rather than something the patient noted
// themselves.
class PulsingHaloDot extends StatefulWidget {
  final Color color;
  final double dotSize;

  const PulsingHaloDot({super.key, required this.color, this.dotSize = 10});

  @override
  State<PulsingHaloDot> createState() => _PulsingHaloDotState();
}

class _PulsingHaloDotState extends State<PulsingHaloDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double haloMax = widget.dotSize * 2.6;
    return SizedBox(
      width: haloMax,
      height: haloMax,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.dotSize + (haloMax - widget.dotSize) * t,
                height: widget.dotSize + (haloMax - widget.dotSize) * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.45),
                ),
              ),
              Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          );
        },
      ),
    );
  }
}
