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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Jump to the bottom instantly
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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
                  size: const Size(80, 120),
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
          bottom: 90,
          left: 90,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withValues(alpha: 0.25),
            child: HorizontalMiniMap(
              controller: _scrollController,
              totalTimelineHeight: 2000.0,
              periods: periods,
              height: 80,
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
      canvas.drawRRect(rect, Paint()..color = period.color.withValues(alpha: 0.2));
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
  final List<TherapyPeriod> periods;
  final DateTime minDate;
  final DateTime maxDate;
  final double? height;

  const HorizontalMiniMap({
    super.key,
    required this.controller,
    required this.totalTimelineHeight,
    required this.periods,
    required this.minDate,
    required this.maxDate,
    this.height,
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
    double widgetHeight = height ?? 80;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final viewportHeight = MediaQuery.of(context).size.height;
            final maxScroll = totalTimelineHeight - viewportHeight;
            final scrollProgress = controller.hasClients ? (controller.offset / maxScroll).clamp(0.0, 1.0) : 0.0;

            const double padding = 4;
            final double handleWidth = constraints.maxWidth * (viewportHeight / totalTimelineHeight);
            final double activeTrackWidth = constraints.maxWidth - (padding * 2);
            final double effectiveHandleWidth = handleWidth - (padding * 2);

            // void handleDrag(double localX) {
            //   if (!controller.hasClients) return;
            //   final double newProgress = ((localX - padding) / activeTrackWidth).clamp(0.0, 1.0);
            //   controller.jumpTo(newProgress * maxScroll);
            // }
            void handleDrag(double localX) {
              if (!controller.hasClients) return;

              // 1. Calculate offset relative to the actual track (subtract padding)
              final double relativeX = (localX - padding).clamp(0.0, activeTrackWidth);

              // 2. Calculate progress based on the usable width
              final double newProgress = (relativeX / activeTrackWidth).clamp(0.0, 1.0);

              // 3. Jump to that position
              controller.jumpTo(newProgress * controller.position.maxScrollExtent);
            }

            return GestureDetector(
              onHorizontalDragUpdate: (details) => handleDrag(details.localPosition.dx),
              onTapDown: (details) => handleDrag(details.localPosition.dx),
              child: Column(
                children: [
                  Text(_getLabel(scrollProgress), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    height: widgetHeight,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6)),
                    child: Stack(
                      children: [
                        // Track Background
                        Padding(
                          padding: const EdgeInsets.all(padding),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.primaryColorLight.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),

                        // Inside your Stack, in HorizontalMiniMap:
                        ...List.generate(periods.length, (i) {
                          final period = periods[i];

                          // 1. Fixed height and spacing logic
                          const double capsuleHeight = 20.0;
                          const double spacing = 4.0;
                          final double top = padding + (i * (capsuleHeight + spacing));

                          // 2. Proportional Horizontal Mapping
                          // Divide the track into equal slots based on the number of periods
                          // This removes the "100px" offset and spreads them across the full width
                          final int totalPeriods = periods.length;
                          final double slotWidth = constraints.maxWidth / totalPeriods;
                          final double capsuleWidth = 80.0; // Your desired width

                          // Center each capsule within its allocated slot
                          final double xPos = (i * slotWidth) + (slotWidth / 2) - (capsuleWidth / 2);

                          return Positioned(
                            top: top,
                            left: xPos.clamp(padding, constraints.maxWidth - capsuleWidth - padding),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                width: capsuleWidth,
                                height: capsuleHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(color: period.color, width: 1.0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }),
                        // The Interactive Handle (Thumb)
                        // The Interactive Handle (Thumb)
                        Positioned(
                          left: padding + (scrollProgress * (activeTrackWidth - effectiveHandleWidth)),
                          child: Container(
                            width: effectiveHandleWidth,
                            height: widgetHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightTheme.primaryColorDark, width: 4.0),
                              borderRadius: BorderRadius.zero,
                            ),
                            // We add a child that shifts the line inside the thumb
                            child: LayoutBuilder(
                              builder: (context, thumbConstraints) {
                                // Calculate how much the line should move based on scroll progress
                                // We want it to stay centered at 0% and 100% scroll
                                final double lineOffset = (thumbConstraints.maxWidth - 2) * scrollProgress;

                                return Stack(
                                  children: [
                                    Positioned(
                                      left: lineOffset,
                                      top: 0,
                                      bottom: 0,
                                      width: 2, // The width of your line
                                      child: CustomPaint(
                                        painter: DashedLinePainter(color: AppTheme.lightTheme.primaryColorDark),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double currentX = 0;

    // Draw the line segment by segment
    canvas.drawLine(Offset(currentX + size.width / 2, 0), Offset(currentX + size.width / 2, size.height), paint);
    currentX += dashWidth + dashSpace;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      ..color = color ?? AppColors.ocean.all[5].withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final Color effectiveIconColor = iconColor ?? Colors.white.withValues(alpha: 0.65);
    final Color effectiveLabelColor = labelColor ?? Colors.white;

    // 3. Move the canvas to the calculated sticky position
    canvas.save();
    canvas.translate(0, bubbleY - yTop);

    // 4. Draw Background
    final RRect backgroundRect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    canvas.drawRRect(backgroundRect, bubblePaint);

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

      // Center icon horizontally, position at top with 8px padding
      final double iconX = (size.width - iconPainter.width) / 2;
      iconPainter.paint(canvas, Offset(iconX, 8));
    }

    if (label != null) {
      final double maxTextWidth = size.width - 16;

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: effectiveLabelColor, fontWeight: FontWeight.w400, fontSize: 16),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxTextWidth);

      // Positioned below icon (assuming icon takes up ~32px of space)
      final double labelY = 32;
      final double labelX = (size.width - labelPainter.width) / 2;

      labelPainter.paint(canvas, Offset(labelX, labelY));
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
