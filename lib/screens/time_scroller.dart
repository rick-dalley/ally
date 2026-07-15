import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../app_theme.dart';
import '../classes/action.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateNeedleTime);
  }

  // void _updateNeedleTime() {
  //   debugPrint("_updateNeedleTime");
  //   if (!_scrollController.hasClients) return;
  //
  //   final double needleY = _scrollController.offset + (MediaQuery.of(context).size.height / 2 - 250);
  //   debugPrint(
  //     "Needle at $needleY vs Action Ys: ${widget.actions.map((a) => (a.occurred * 1000 - widget.startTime.millisecondsSinceEpoch) / (widget.endTime.millisecondsSinceEpoch - widget.startTime.millisecondsSinceEpoch) * 2000).toList()}",
  //   );
  //
  //   // Use UTC milliseconds for all calculations
  //   final startMs = widget.startTime.millisecondsSinceEpoch;
  //   final endMs = widget.endTime.millisecondsSinceEpoch;
  //   final totalDuration = endMs - startMs;
  //
  //   final double progress = (needleY / timelineHeight).clamp(0.0, 1.0);
  //   final int currentMillis = (startMs + (progress * totalDuration)).toInt();
  //
  //   _needleTime.value = DateFormat(
  //     'MMM d, HH:mm',
  //   ).format(DateTime.fromMillisecondsSinceEpoch(currentMillis, isUtc: true));
  //
  //   // Find nearest action
  //   PatientAction? closest;
  //   double minDistance = 50.0;
  //   for (var action in widget.actions) {
  //     // action.occurred MUST be compared against startMs in UTC
  //     final actionProgress = (action.occurred - startMs) / totalDuration;
  //     final actionY = timelineHeight * actionProgress;
  //
  //     if ((actionY - needleY).abs() < minDistance) {
  //       closest = action;
  //       minDistance = (actionY - needleY).abs();
  //     }
  //   }
  //   _activeAction.value = closest;
  // }
  void _updateNeedleTime() {
    if (!_scrollController.hasClients || widget.actions.isEmpty) return;

    // 1. Calculate the real bounds of your data
    final List<int> allTimes = widget.actions.map((a) => a.occurred * 1000).toList();
    final int minMs = allTimes.reduce((a, b) => a < b ? a : b);
    final int maxMs = allTimes.reduce((a, b) => a > b ? a : b);
    final int range = (maxMs - minMs) > 0 ? (maxMs - minMs) : 1;

    final double needleY = _scrollController.offset + (MediaQuery.of(context).size.height / 2 - 250);

    // 2. Map needleY to the range
    final double progress = (needleY / timelineHeight).clamp(0.0, 1.0);
    final int currentMillis = minMs + (progress * range).toInt();

    _needleTime.value = DateFormat(
      'MMM d, HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(currentMillis, isUtc: true));

    // 3. Find closest using the same normalized range
    PatientAction? closest;
    double minDistance = 100.0;
    for (var action in widget.actions) {
      final double actionProgress = ((action.occurred * 1000) - minMs) / range;
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
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 250),
            child: SizedBox(
              height: 2000,
              width: double.infinity,
              child: ValueListenableBuilder<PatientAction?>(
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
            ),
          ),
        ),
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
                    Text(
                      DateFormat('MMM d, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(action.occurred * 1000)),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey, margin: EdgeInsets.symmetric(horizontal: 10)),
                    Text(action.getName(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
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

  // double calculateY(int occurred, double canvasHeight) {
  //   final totalDuration = endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;
  //   final progress = ((occurred * 1000) - startTime.millisecondsSinceEpoch) / totalDuration;
  //   return canvasHeight * progress.clamp(0.0, 1.0);
  // }
  double calculateY(int occurred, double canvasHeight) {
    final int startMs = startTime.millisecondsSinceEpoch;
    final int endMs = endTime.millisecondsSinceEpoch;
    final int totalDuration = endMs - startMs;

    // FIX: Ensure you are consistently comparing milliseconds to milliseconds
    final int occurredMs = occurred * 1000;
    final double progress = (occurredMs - startMs) / totalDuration;

    return canvasHeight * progress.clamp(0.0, 1.0);
  }

  String _formatByInterval(DateTime time, Duration interval) {
    if (interval.inMinutes <= 15) return DateFormat('HH:mm').format(time);
    if (interval.inHours == 1) return DateFormat('HH:00').format(time);
    return DateFormat('MMM dd').format(time);
  }

  @override
  @override
  void paint(Canvas canvas, Size size) {
    if (actions.isEmpty) return;

    final double axisX = 80.0;

    // 1. NORMALIZE: Use the actual data bounds to ensure 0.0 to 1.0 progress
    final List<int> allTimes = actions.map((a) => a.occurred * 1000).toList();
    final int minMs = allTimes.reduce((a, b) => a < b ? a : b);
    final int maxMs = allTimes.reduce((a, b) => a > b ? a : b);
    final int rangeMs = (maxMs - minMs) > 0 ? (maxMs - minMs) : 1;

    // 2. Draw smart increments based on normalized range
    DateTime minDate = DateTime.fromMillisecondsSinceEpoch(minMs, isUtc: true);
    DateTime maxDate = DateTime.fromMillisecondsSinceEpoch(maxMs, isUtc: true);

    Duration interval;
    if (rangeMs < Duration(hours: 2).inMilliseconds) {
      interval = const Duration(minutes: 15);
    } else if (rangeMs < Duration(hours: 24).inMilliseconds) {
      interval = const Duration(hours: 1);
    } else if (rangeMs < Duration(days: 7).inMilliseconds) {
      interval = const Duration(days: 1);
    } else {
      interval = const Duration(days: 7);
    }

    DateTime currentTime = minDate;
    while (currentTime.isBefore(maxDate.add(interval))) {
      final double progress = (currentTime.millisecondsSinceEpoch - minMs) / rangeMs;
      final double y = size.height * progress.clamp(0.0, 1.0);

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

    // 3. Draw Axis
    canvas.drawLine(
      Offset(axisX, 0),
      Offset(axisX, size.height),
      Paint()
        ..color = AppColors.ocean.all[5]
        ..strokeWidth = 1.0,
    );

    // 4. Draw Events
    for (var action in actions) {
      final double progress = ((action.occurred * 1000) - minMs) / rangeMs;
      final double y = size.height * progress.clamp(0.0, 1.0);

      if (activeAction != null && action.id == activeAction!.id) {
        canvas.drawCircle(Offset(axisX, y), 8, Paint()..color = Colors.orange.withValues(alpha: 0.3));
      }
      canvas.drawCircle(Offset(axisX, y), 4, Paint()..color = Colors.orange);
    }
  }

  @override
  bool shouldRepaint(covariant TimeLinePainter oldDelegate) {
    // MUST compare both the action list and the activeAction
    return oldDelegate.activeAction != activeAction || oldDelegate.actions != actions;
  }
}
