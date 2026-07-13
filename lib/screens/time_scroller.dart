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
  // Using a ValueNotifier for high-performance updates
  final ValueNotifier<String> _needleTime = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();
    _needleTime.value = DateFormat('HH:mm').format(widget.startTime);
    _scrollController.addListener(_updateNeedleTime);
  }

  void _updateNeedleTime() {
    if (!_scrollController.hasClients) return;

    final double scrollOffset = _scrollController.offset;
    // Offset by the padding we added (250) to keep alignment accurate
    final double adjustedOffset = (scrollOffset - 250).clamp(0, 2000);
    final double progress = adjustedOffset / 2000;

    final totalDuration = widget.endTime.difference(widget.startTime).inMilliseconds;
    final int currentMillis = widget.startTime.millisecondsSinceEpoch + (progress * totalDuration).toInt();

    _needleTime.value = DateFormat('MMM d, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(currentMillis));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _needleTime.dispose();
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
              child: CustomPaint(
                painter: TimeLinePainter(actions: widget.actions, startTime: widget.startTime, endTime: widget.endTime),
              ),
            ),
          ),
        ),
        // Stationary Gauge Needle
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height / 2 - 50,
          child: IgnorePointer(
            child: Column(
              children: [
                // THIS now updates specifically without rebuilding the whole list
                ValueListenableBuilder<String>(
                  valueListenable: _needleTime,
                  builder: (context, time, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        time,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                Row(
                  children: List.generate(
                    40,
                    (i) => Expanded(child: Container(height: 2, color: i % 2 == 0 ? Colors.red : Colors.transparent)),
                  ),
                ),
              ],
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

  TimeLinePainter({required this.actions, required this.startTime, required this.endTime});

  @override
  void paint(Canvas canvas, Size size) {
    final double axisX = 80.0;
    final totalDuration = endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;

    // Draw increments on the left
    final int numIncrements = 15;
    for (int i = 0; i <= numIncrements; i++) {
      final double y = (size.height / numIncrements) * i;
      final DateTime time = startTime.add(Duration(milliseconds: (totalDuration / numIncrements * i).toInt()));

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: DateFormat('HH:mm').format(time),
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(20, y - 5));
    }

    canvas.drawLine(
      Offset(axisX, 0),
      Offset(axisX, size.height),
      Paint()
        ..color = Colors.blueGrey.shade200
        ..strokeWidth = 2.0,
    );

    for (var action in actions) {
      final double progress = ((action.occurred * 1000) - startTime.millisecondsSinceEpoch) / totalDuration;
      final double y = size.height * progress;

      final Rect bubble = Rect.fromLTWH(axisX + 20, y - 15, 200, 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubble, const Radius.circular(15)),
        Paint()..color = Colors.blue.shade100,
      );

      final TextPainter lp = TextPainter(
        text: TextSpan(
          text: action.getName(),
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(axisX + 30, y - (lp.height / 2)));
    }
  }

  @override
  bool shouldRepaint(covariant TimeLinePainter oldDelegate) => true;
}
