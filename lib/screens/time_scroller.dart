import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'dart:ui' as ui;
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient_action.dart';
import '../classes/timeline_span.dart';
import '../widgets/timeline_span_picker_sheet.dart';

// Colors are assigned by lane position, not baked into the span itself — up to three
// spans render together and need to stay visually distinct no matter which categories
// the patient actually picks (three medications picked together shouldn't all be the
// same color). Real Carbon semantic tokens, not invented hex values.
const List<Color> _laneColors = [carbonColorSupportInfo, carbonColorSupportSuccess, carbonColorSupportCautionMajor];

class TimelineScrollerWidget extends StatefulWidget {
  final String patientUuid;

  const TimelineScrollerWidget({super.key, required this.patientUuid});

  @override
  State<TimelineScrollerWidget> createState() => TimelineScrollerWidgetState();
}

class TimelineScrollerWidgetState extends State<TimelineScrollerWidget> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _needleTime = ValueNotifier<String>("");
  final ValueNotifier<PatientAction?> _activeAction = ValueNotifier<PatientAction?>(null);
  final double timelineHeight = 2000.0;

  bool _loading = true;
  bool _isExample = false;
  List<PatientAction> actions = [];
  List<TimelineSpan> availableSpans = [];
  List<TimelineSpan> selectedSpans = [];
  late DateTime startTime;
  late DateTime endTime;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateNeedleTime);
    _load();
  }

  Future<void> _load() async {
    final bool sufficient = await DatabaseManager().hasSufficientTimelineData(widget.patientUuid);

    if (sufficient) {
      final rows = await DatabaseManager().getTimelineEventRows(widget.patientUuid);
      final List<PatientAction> loadedActions =
          [
            ...rows['doses']!.map(PatientAction.medicationDose),
            ...rows['appointments']!.map(PatientAction.appointment),
            ...rows['symptoms']!.map(PatientAction.symptom),
            ...rows['moods']!.map(PatientAction.mood),
            ...rows['tests']!.map(PatientAction.test),
          ]..sort((a, b) => a.occurred.compareTo(b.occurred));

      final medRows = await DatabaseManager().getMedicationSpanRows(widget.patientUuid);
      final conditionRows = await DatabaseManager().getConditionSpanRows(widget.patientUuid);
      final providerRows = await DatabaseManager().getProviderSpanRows(widget.patientUuid);
      final List<TimelineSpan> loadedSpans =
          [
            ...medRows.map(PeriodSpan.medication),
            ...conditionRows.map(PeriodSpan.condition),
            ...providerRows.map(PeriodSpan.provider),
          ]..sort((a, b) => b.startDate.compareTo(a.startDate));

      final DateTime earliest = [
        loadedActions.first.occurred,
        ...loadedSpans.map((s) => s.startDate),
      ].reduce((a, b) => a.isBefore(b) ? a : b);

      if (!mounted) return;
      setState(() {
        actions = loadedActions;
        availableSpans = loadedSpans;
        selectedSpans = loadedSpans.take(3).toList();
        startTime = earliest;
        endTime = DateTime.now();
        _isExample = false;
        _loading = false;
      });
    } else {
      final example = TimelineExampleData.build();
      if (!mounted) return;
      setState(() {
        actions = example.actions;
        availableSpans = example.spans;
        selectedSpans = example.spans;
        startTime = example.startTime;
        endTime = example.endTime;
        _isExample = true;
        _loading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _openPicker() async {
    final List<TimelineSpan>? result = await showModalBottomSheet<List<TimelineSpan>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => TimelineSpanPickerSheet(available: availableSpans, initiallySelected: selectedSpans),
    );
    if (result != null) setState(() => selectedSpans = result);
  }

  void _updateNeedleTime() {
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
    final Duration totalDuration = endTime.difference(startTime);

    // Calculate the time at the needle position
    final DateTime currentDateTime = startTime.add(totalDuration * progress);

    _needleTime.value = DateFormat('MMM d, HH:mm').format(currentDateTime);

    // Find closest action using native DateTime comparisons
    PatientAction? closest;
    double minDistance = 25.0;

    for (var action in actions) {
      // Calculate how far this action is from the start time as a ratio
      final double actionProgress = action.occurred.difference(startTime).inMilliseconds / totalDuration.inMilliseconds;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final double screenWidth = MediaQuery.sizeOf(context).width;
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 250),
            child: SizedBox(
              height: 2000,
              width: screenWidth,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: TherapyPeriodPainter(
                      spans: selectedSpans,
                      canvasHeight: 2000,
                      startTime: startTime,
                      endTime: endTime,
                      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
                    ),
                    size: Size.infinite,
                  ),
                  ValueListenableBuilder<PatientAction?>(
                    valueListenable: _activeAction,
                    builder: (context, activeAction, child) {
                      return CustomPaint(
                        painter: TimeLinePainter(
                          actions: actions,
                          startTime: startTime,
                          endTime: endTime,
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
        ...List.generate(selectedSpans.length, (i) {
          final span = selectedSpans[i];
          final Duration totalDuration = endTime.difference(startTime);
          final double totalMs = totalDuration.inMilliseconds.toDouble();
          final double startProgress = span.startDate.difference(startTime).inMilliseconds / totalMs;
          final double yTop = (2000.0 * startProgress.clamp(0.0, 1.0));
          final double xPos = 100.0 + (i * 100.0);
          final double endProgress = span.endDate.difference(startTime).inMilliseconds / totalMs;
          final double yBottom = (2000.0 * endProgress.clamp(0.0, 1.0));
          return AnimatedBuilder(
            animation: _scrollController,
            builder: (context, _) {
              return Positioned(
                top: yTop - _scrollController.offset + 250, // 250 is your padding
                left: xPos,
                child: CustomPaint(
                  size: const Size(72, 120),
                  painter: CapsuleSliderBubble(
                    icon: span.category.icon,
                    label: span.label,
                    color: _laneColors[i % _laneColors.length],
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
                      child: Text(time, style: TextStyle(color: AppTheme.primaryColor, fontSize: 20)),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    80,
                    (i) => Expanded(
                      child: Container(height: 1, color: i % 2 == 0 ? AppTheme.primaryColor : Colors.transparent),
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
                  color: AppTheme.onPrimaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Text(DateFormat('MMM d, HH:mm').format(action.occurred)),
                    Container(width: 1, height: 20, color: Colors.grey, margin: EdgeInsets.symmetric(horizontal: 10)),
                    Expanded(child: Text(action.description, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
          ),
        ),
        // Example-data banner — unmissable while example data is showing, gone the
        // instant real data clears the threshold (see hasSufficientTimelineData).
        if (_isExample)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                color: carbonColorSupportCautionMajor,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  "Showing example data — keep logging for about a week and this fills in with yours.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: carbonColorButtonOnPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
          ),
        Positioned(
          top: _isExample ? 40 : 8,
          right: 8,
          child: SafeArea(
            bottom: false,
            child: FloatingActionButton.small(
              heroTag: "timeline_compare",
              onPressed: _isExample ? null : _openPicker,
              tooltip: "Choose what to compare",
              child: const Icon(Symbols.compare_arrows),
            ),
          ),
        ),
        Positioned(
          bottom: 90,
          left: 16,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.onPrimaryColor.withValues(alpha: 0.25),
            child: HorizontalMiniMap(
              controller: _scrollController,
              totalTimelineHeight: 2000.0,
              spans: selectedSpans,
              height: 80,
              minDate: startTime,
              maxDate: endTime,
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
        text: TextSpan(text: _formatByInterval(currentTime, interval), style: AppTheme.defaultHintStyle),
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
        ..color = AppTheme.primaryColor
        ..strokeWidth = 1.0,
    );

    // Draw Events
    for (var action in actions) {
      final double y = calculateY(action.occurred, size.height);

      if (activeAction != null && action.actionType == activeAction!.actionType) {
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
  final List<TimelineSpan> spans;
  final DateTime startTime;
  final DateTime endTime;
  final double canvasHeight;
  final double scrollOffset;
  final double topPadding;

  TherapyPeriodPainter({
    required this.spans,
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

    for (int i = 0; i < spans.length; i++) {
      final span = spans[i];
      final Color color = _laneColors[i % _laneColors.length];

      final double startProgress = span.startDate.difference(startTime).inMilliseconds / totalMs;
      final double endProgress = span.endDate.difference(startTime).inMilliseconds / totalMs;

      final double yTop = canvasHeight * startProgress.clamp(0.0, 1.0);
      final double yBottom = canvasHeight * endProgress.clamp(0.0, 1.0);
      final double height = (yBottom - yTop).clamp(20.0, canvasHeight);

      final double xPos = 100.0 + (i * 100.0);

      // Draw the capsule
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(xPos, yTop, 80, height), const Radius.circular(32));
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    }
  }

  @override
  bool shouldRepaint(covariant TherapyPeriodPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.spans != spans ||
        oldDelegate.startTime != startTime ||
        oldDelegate.endTime != endTime;
  }
}

class HorizontalMiniMap extends StatelessWidget {
  final ScrollController controller;
  final double totalTimelineHeight;
  final List<TimelineSpan> spans;
  final DateTime minDate;
  final DateTime maxDate;
  final double? height;

  const HorizontalMiniMap({
    super.key,
    required this.controller,
    required this.totalTimelineHeight,
    required this.spans,
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
                  const SizedBox(height: 4),
                  Container(
                    height: widgetHeight,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6)),
                    child: Stack(
                      children: [
                        // Track Background
                        Padding(
                          padding: const EdgeInsets.all(padding),
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  // Use white with a low opacity for a translucent white frost,
                                  // or blend it with your primary color if you prefer a tinted glow.
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(color: carbonColorBorderSubtle00),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Inside your Stack, in HorizontalMiniMap:
                        ...List.generate(spans.length, (i) {
                          final Color color = _laneColors[i % _laneColors.length];

                          // 1. Fixed height and spacing logic
                          const double capsuleHeight = 20.0;
                          const double spacing = 4.0;
                          final double top = padding + (i * (capsuleHeight + spacing));

                          // 2. Proportional Horizontal Mapping
                          // Divide the track into equal slots based on the number of periods
                          // This removes the "100px" offset and spreads them across the full width
                          final int totalPeriods = spans.length;
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
                                  border: Border.all(color: color, width: 1.0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }),
                        // The Interactive Handle (Thumb)
                        Positioned(
                          left: padding + (scrollProgress * (activeTrackWidth - effectiveHandleWidth)),
                          child: Container(
                            width: effectiveHandleWidth,
                            height: widgetHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryColor, width: 4.0),
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
                                      child: CustomPaint(painter: DashedLinePainter(color: AppTheme.primaryColor)),
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
    double bubbleX = (80 - size.width) * 0.5;
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
      ..color = color ?? AppTheme.primaryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final Color effectiveIconColor = iconColor ?? AppTheme.onPrimaryColor.withValues(alpha: 0.65);
    final Color effectiveLabelColor = labelColor ?? AppTheme.onPrimaryColor;

    // 3. Move the canvas to the calculated sticky position
    canvas.save();
    canvas.translate(bubbleX, bubbleY - yTop);

    // 4. Draw Background
    final RRect backgroundRect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(32));
    canvas.drawRRect(backgroundRect, bubblePaint);

    if (icon != null) {
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon!.codePoint),
          style: TextStyle(
            fontSize: 20,
            fontFamily: icon!.fontFamily,
            package: icon!.fontPackage,
            color: effectiveIconColor,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // Center icon horizontally, position at top with 8px padding
      final double iconX = (size.width - iconPainter.width) / 2;
      iconPainter.paint(canvas, Offset(iconX, 16));
    }

    if (label != null) {
      final double maxTextWidth = size.width - 8;

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: effectiveLabelColor, fontWeight: FontWeight.w400, fontSize: 16),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxTextWidth);

      // Positioned below icon (assuming icon takes up ~32px of space)
      final double labelY = 48;
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
