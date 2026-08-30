import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// A small glyph with a soft, breathing ring around it — used where a plain static dot
// (see the red "unseen" dots elsewhere on the profile screen) isn't loud enough on its
// own, e.g. a doctor's order landing rather than something the patient noted
// themselves. Defaults to Symbols.bigtop_updates — the standard "something new
// arrived" glyph — rather than a plain circle, so the badge itself already reads as a
// notification rather than needing a separate dot drawn on top of it.
class PulsingHaloDot extends StatefulWidget {
  final Color color;
  final double size;
  final IconData icon;

  const PulsingHaloDot({super.key, required this.color, this.size = 18, this.icon = Symbols.bigtop_updates});

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
    final double haloMax = widget.size * 2.2;
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
                width: widget.size + (haloMax - widget.size) * t,
                height: widget.size + (haloMax - widget.size) * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.45),
                ),
              ),
              Icon(widget.icon, size: widget.size, color: widget.color),
            ],
          );
        },
      ),
    );
  }
}
