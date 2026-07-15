import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../app_theme.dart';
import '../classes/action.dart';

class TherapyPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final String name;
  final Color color;
  final IconData icon;

  TherapyPeriod({
    required this.startDate,
    required this.endDate,
    required this.name,
    required this.color,
    required this.icon,
  });
}

class TimelineScrollerWidget extends StatefulWidget {
  final List<PatientAction> actions;
  final DateTime startTime;
  final DateTime endTime;

  const TimelineScrollerWidget({super.key, required this.actions, required this.startTime, required this.endTime});

  @override
  State<TimelineScrollerWidget> createState() => TimelineScrollerWidgetState();
}

class TimelineScrollerWidgetState extends State<TimelineScrollerWidget> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _needleTime = ValueNotifier<String>("");
  final ValueNotifier<PatientAction?> _activeAction = ValueNotifier<PatientAction?>(null);
  final double timelineHeight = 2000.0;

  late int minMs;
  late int maxMs;
  late int rangeMs;
  List<TherapyPeriod> periods = [];
  @override
  void initState() {
    super.initState();
    periods = getMockPeriods();
    _scrollController.addListener(_updateNeedleTime);
  }

  void _updateNeedleTime() {
    if (!_scrollController.hasClients) return;

    if (!_scrollController.hasClients) return;

    // Get the viewport center in global screen coordinates
    final double viewportCenter = MediaQuery.of(context).size.height / 2;

    // Subtract the top padding to get the Y position INSIDE the 2000px box
    // This is the needle position relative to the start of the 2000px timeline
    final double needleY =
        _scrollController.offset + viewportCenter - 264; //264 is a hack that just seems to make everything line up.

    // Now the progress is strictly within the 2000px bounds
    final double progress = (needleY / 2000.0).clamp(0.0, 1.0);

    // Derive the time using native DateTime duration math
    final Duration totalDuration = widget.endTime.difference(widget.startTime);

    // Calculate the time at the needle position
    final DateTime currentDateTime = widget.startTime.add(totalDuration * progress);

    _needleTime.value = DateFormat('MMM d, HH:mm').format(currentDateTime);

    // Find closest action using native DateTime comparisons
    PatientAction? closest;
    double minDistance = 25.0;

    for (var action in widget.actions) {
      // Calculate how far this action is from the start time as a ratio
      final double actionProgress =
          action.occurred.difference(widget.startTime).inMilliseconds / totalDuration.inMilliseconds;
      final double actionY = timelineHeight * actionProgress;

      if ((actionY - needleY).abs() < minDistance) {
        closest = action;
        minDistance = (actionY - needleY).abs();
      }
    }
    _activeAction.value = closest;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _needleTime.dispose();
    _activeAction.dispose();
    super.dispose();
  }

  List<TherapyPeriod> getMockPeriods() {
    final Duration totalDuration = widget.endTime.difference(widget.startTime);

    return [
      TherapyPeriod(
        name: "Medication X",
        color: Colors.red,
        // Use the duration multiplication and addition directly on the DateTime
        startDate: widget.startTime.add(totalDuration * 0.1),
        endDate: widget.startTime.add(totalDuration * 0.4),
        icon: Icons.medication,
      ),
      TherapyPeriod(
        name: "CPAP Therapy",
        color: Colors.green,
        startDate: widget.startTime.add(totalDuration * 0.3),
        endDate: widget.startTime.add(totalDuration * 0.7),
        icon: Icons.air,
      ),
      TherapyPeriod(
        name: "Physical Therapy",
        color: Colors.blue,
        startDate: widget.startTime.add(totalDuration * 0.75),
        endDate: widget.startTime.add(totalDuration * 0.95),
        icon: Icons.fitness_center,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 250),
            child: SizedBox(
              height: 2000,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: TherapyPeriodPainter(
                      periods: periods,
                      canvasHeight: 2000,
                      startTime: widget.startTime,
                      endTime: widget.endTime,
                      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
                    ),
                    size: Size.infinite,
                  ),
                  ValueListenableBuilder<PatientAction?>(
                    valueListenable: _activeAction,
                    builder: (context, activeAction, child) {
                      return CustomPaint(
                        painter: TimeLinePainter(
                          actions: widget.actions,
                          startTime: widget.startTime,
                          endTime: widget.endTime,
                          activeAction: activeAction,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        ...List.generate(periods.length, (i) {
          final period = periods[i];
          // Calculate yTop here using the same math you used in your painter
          final Duration totalDuration = widget.endTime.difference(widget.startTime);
          final double totalMs = totalDuration.inMilliseconds.toDouble();
          final double startProgress = period.startDate.difference(widget.startTime).inMilliseconds / totalMs;
          final double yTop = (2000.0 * startProgress.clamp(0.0, 1.0));
          final double xPos = 100.0 + (i * 100.0);
          final double endProgress =
              period.endDate.difference(widget.startTime).inMilliseconds / totalDuration.inMilliseconds.toDouble();
          final double yBottom = (2000.0 * endProgress.clamp(0.0, 1.0));
          return AnimatedBuilder(
            animation: _scrollController,
            builder: (context, _) {
              return Positioned(
                top: yTop - _scrollController.offset + 250, // 250 is your padding
                left: xPos,
                child: CustomPaint(
                  size: const Size(120, 40),
                  painter: CapsuleSliderBubble(
                    icon: period.icon,
                    label: period.name,
                    color: period.color,
                    scrollOffset: _scrollController.offset,
                    yTop: yTop,
                    yBottom: yBottom,
                  ),
                ),
              );
            },
          );
        }),
        // Gauge Needle
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height / 2 - 50,
          child: IgnorePointer(
            child: Column(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _needleTime,
                  builder: (context, time, child) => Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(time, style: TextStyle(color: AppColors.oceanBlue, fontSize: 20)),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    80,
                    (i) => Expanded(
                      child: Container(height: 1, color: i % 2 == 0 ? AppColors.oceanBlue : Colors.transparent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Toast
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: ValueListenableBuilder<PatientAction?>(
            valueListenable: _activeAction,
            builder: (context, action, child) {
              if (action == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Text(DateFormat('MMM d, HH:mm').format(action.occurred)),
                    Container(width: 1, height: 20, color: Colors.grey, margin: EdgeInsets.symmetric(horizontal: 10)),
                    Text(action.getName(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withValues(alpha: 0.9),
            child: HorizontalMiniMap(
              controller: _scrollController,
              totalTimelineHeight: 2000.0,
              minDate: widget.startTime, // Use the injected start
              maxDate: widget.endTime, // Use the injected end
            ),
          ),
        ),
      ],
    );
  }
}

class TimeLinePainter extends CustomPainter {
  final List<PatientAction> actions;
  final DateTime startTime;
  final DateTime endTime;
  final PatientAction? activeAction;

  TimeLinePainter({required this.actions, required this.startTime, required this.endTime, this.activeAction});

  double calculateY(DateTime occurred, double canvasHeight) {
    final Duration total = endTime.difference(startTime);
    final Duration elapsed = occurred.difference(startTime);
    // Use ratio of microseconds to avoid integer truncation and double precision drift
    final double progress = elapsed.inMicroseconds / total.inMicroseconds;
    return canvasHeight * progress.clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (actions.isEmpty) return;

    final double axisX = 80.0;
    final Duration totalDuration = endTime.difference(startTime);

    // Determine smart interval based on the total duration window
    Duration interval;
    if (totalDuration < const Duration(hours: 2)) {
      interval = const Duration(minutes: 15);
    } else if (totalDuration < const Duration(hours: 24)) {
      interval = const Duration(hours: 1);
    } else if (totalDuration < const Duration(days: 7)) {
      interval = const Duration(days: 1);
    } else {
      interval = const Duration(days: 7);
    }

    // Draw smart increments
    DateTime currentTime = startTime;
    while (currentTime.isBefore(endTime.add(interval))) {
      final double y = calculateY(currentTime, size.height);

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: _formatByInterval(currentTime, interval),
          style: TextStyle(color: AppColors.grey.all[6], fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(20, y - 5));
      currentTime = currentTime.add(interval);
    }

    // Draw Axis
    canvas.drawLine(
      Offset(axisX, 0),
      Offset(axisX, size.height),
      Paint()
        ..color = AppColors.ocean.all[5]
        ..strokeWidth = 1.0,
    );

    // Draw Events
    for (var action in actions) {
      final double y = calculateY(action.occurred, size.height);

      if (activeAction != null && action.id == activeAction!.id) {
        canvas.drawCircle(Offset(axisX, y), 8, Paint()..color = Colors.orange.withValues(alpha: 0.3));
      }
      canvas.drawCircle(Offset(axisX, y), 4, Paint()..color = Colors.orange);
    }
  }

  String _formatByInterval(DateTime time, Duration interval) {
    if (interval.inMinutes <= 15) return DateFormat('HH:mm').format(time);
    if (interval.inHours == 1) return DateFormat('HH:00').format(time);
    return DateFormat('MMM dd').format(time);
  }

  @override
  bool shouldRepaint(covariant TimeLinePainter oldDelegate) {
    return oldDelegate.activeAction != activeAction ||
        oldDelegate.actions != actions ||
        oldDelegate.startTime != startTime ||
        oldDelegate.endTime != endTime;
  }
}

class TherapyPeriodPainter extends CustomPainter {
  final List<TherapyPeriod> periods;
  final DateTime startTime;
  final DateTime endTime;
  final double canvasHeight;
  final double scrollOffset;
  final double topPadding;

  TherapyPeriodPainter({
    required this.periods,
    required this.startTime,
    required this.endTime,
    required this.canvasHeight,
    required this.scrollOffset,
    this.topPadding = 250.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Duration totalDuration = endTime.difference(startTime);
    final double totalMs = totalDuration.inMilliseconds.toDouble();

    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];

      final double startProgress = period.startDate.difference(startTime).inMilliseconds / totalMs;
      final double endProgress = period.endDate.difference(startTime).inMilliseconds / totalMs;

      final double yTop = canvasHeight * startProgress.clamp(0.0, 1.0);
      final double yBottom = canvasHeight * endProgress.clamp(0.0, 1.0);
      final double height = (yBottom - yTop).clamp(20.0, canvasHeight);

      final double xPos = 100.0 + (i * 100.0);

      // Draw the capsule
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(xPos, yTop, 80, height), const Radius.circular(12));
      canvas.drawRRect(rect, Paint()..color = period.color.withOpacity(0.2));
    }
  }

  @override
  bool shouldRepaint(covariant TherapyPeriodPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.periods != periods ||
        oldDelegate.startTime != startTime ||
        oldDelegate.endTime != endTime;
  }
}

class HorizontalMiniMap extends StatelessWidget {
  final ScrollController controller;
  final double totalTimelineHeight;
  final DateTime minDate;
  final DateTime maxDate;

  const HorizontalMiniMap({
    super.key,
    required this.controller,
    required this.totalTimelineHeight,
    required this.minDate,
    required this.maxDate,
  });

  String _getLabel(double progress) {
    // Use duration math directly instead of milliseconds.toInt()
    final Duration range = maxDate.difference(minDate);
    final DateTime currentTime = minDate.add(range * progress);

    // Logic for dynamic labels based on span
    if (range.inDays > 730) {
      // Show seasons
      final month = currentTime.month;
      if (month >= 3 && month <= 5) return "Spring";
      if (month >= 6 && month <= 8) return "Summer";
      if (month >= 9 && month <= 11) return "Fall";
      return "Winter";
    } else {
      return DateFormat('MMM').format(currentTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final viewportHeight = MediaQuery.of(context).size.height;
            final scrollProgress = controller.hasClients
                ? (controller.offset / (totalTimelineHeight - viewportHeight)).clamp(0.0, 1.0)
                : 0.0;

            return Column(
              children: [
                // Dynamic Label
                Text(_getLabel(scrollProgress), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Slider Track
                Container(
                  height: 12,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                  child: Stack(
                    children: [
                      Positioned(
                        left:
                            scrollProgress *
                            (constraints.maxWidth - (constraints.maxWidth * (viewportHeight / totalTimelineHeight))),
                        child: Container(
                          width: constraints.maxWidth * (viewportHeight / totalTimelineHeight),
                          height: 12,
                          decoration: BoxDecoration(color: AppColors.oceanBlue, borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class VerticalMiniMap extends StatelessWidget {
  final ScrollController controller;
  final double totalHeight;

  const VerticalMiniMap({super.key, required this.controller, this.totalHeight = 2000.0});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      width: 40,
      height: 200, // Fixed height for the mini-map
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final double viewportHeight = MediaQuery.of(context).size.height;
          // Calculate the proportional handle height
          final double handleHeight = (viewportHeight / totalHeight) * 200;

          // Calculate the handle offset
          final double scrollProgress = controller.hasClients
              ? (controller.offset / (totalHeight - viewportHeight)).clamp(0.0, 1.0)
              : 0.0;
          final double topOffset = scrollProgress * (200 - handleHeight);

          return Container(
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
            child: Stack(
              children: [
                Positioned(
                  top: topOffset,
                  left: 2,
                  right: 2,
                  child: Container(
                    height: handleHeight,
                    decoration: BoxDecoration(color: AppColors.oceanBlue, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CapsuleSliderBubble extends CustomPainter {
  final IconData? icon;
  final String? label;
  final Color? color;
  final Color? iconColor;
  final Color? labelColor;

  // These make the painter "self-aware" of its scroll position
  final double scrollOffset;
  final double yTop;
  final double yBottom;
  final double topPadding;

  CapsuleSliderBubble({
    this.icon,
    this.label,
    this.color,
    this.iconColor,
    this.labelColor,
    required this.scrollOffset,
    required this.yTop,
    required this.yBottom,
    this.topPadding = 250.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate Sticky Position
    // The painter calculates its own effective Y based on scrollOffset
    double bubbleY = yTop;
    double viewportTop = scrollOffset - topPadding;
    if (bubbleY > yBottom - 20) return;
    // Pin logic
    if (yTop < viewportTop + 16) {
      bubbleY = viewportTop + 16;
    }
    if (bubbleY > yBottom - size.height - 16) {
      bubbleY = yBottom - size.height - 16;
    }
    // 2. Define Styles
    final Paint bubblePaint = Paint()
      ..color = color ?? Colors.blue.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final Color effectiveIconColor = iconColor ?? Colors.black.withOpacity(0.65);
    final Color effectiveLabelColor = labelColor ?? Colors.black;

    // 3. Move the canvas to the calculated sticky position
    canvas.save();
    canvas.translate(0, bubbleY - yTop);

    // 4. Draw Background
    final RRect rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    canvas.drawRRect(rrect, bubblePaint);

    // 5. Draw Icon
    if (icon != null) {
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon!.codePoint),
          style: TextStyle(
            fontSize: 24,
            fontFamily: icon!.fontFamily,
            package: icon!.fontPackage,
            color: effectiveIconColor,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, Offset(8, (size.height - iconPainter.height) / 2));
    }

    // 6. Draw Text
    if (label != null) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: effectiveLabelColor, fontWeight: FontWeight.w400, fontSize: 16),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(40, (size.height - textPainter.height) / 2));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CapsuleSliderBubble oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.yTop != yTop ||
        oldDelegate.label != label ||
        oldDelegate.icon != icon ||
        oldDelegate.color != color;
  }
}

//
// class CapsuleSliderBubble extends StatelessWidget {
//   final IconData? icon;
//   final Color? color;
//   final Color? iconColor;
//   final Color? labelColor;
//   final String? label;
//
//   const CapsuleSliderBubble({super.key, this.icon, this.label, this.color, this.iconColor, this.labelColor});
//
//   @override
//   Widget build(BuildContext context) {
//     Color bubbleColor = color ?? AppColors.oceanBlue.withValues(alpha: .85);
//     Color bubbleIconColor = iconColor ?? AppColors.oceanBlue.withValues(alpha: 0.65); // Darkest (text/icon)
//     Color bubbleLabelColor = labelColor ?? AppColors.ocean.all[6];
//     String bubbleLabel = label ?? "";
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(20)),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: bubbleIconColor, size: 24),
//           const SizedBox(width: 8),
//           Text(
//             bubbleLabel,
//             style: TextStyle(color: bubbleLabelColor, fontWeight: FontWeight.w400),
//           ),
//         ],
//       ),
//     );
//   }
// }
