import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';

// No calendar package is installed in this app — hand-rolled rather than adding a
// dependency for a fairly simple 7-column grid. Two distinct markers per day: a dot
// for "something health-related happened" (shown whether or not a note was written —
// these are memory prompts, not a report of what's been journaled) and a second,
// different-colored dot for "you wrote a note here".
class DiaryMonthCalendar extends StatefulWidget {
  final String patientUuid;
  final DateTime initialMonth;
  final ValueChanged<DateTime> onDaySelected;

  const DiaryMonthCalendar({
    super.key,
    required this.patientUuid,
    required this.initialMonth,
    required this.onDaySelected,
  });

  @override
  State<DiaryMonthCalendar> createState() => _DiaryMonthCalendarState();
}

class _DiaryMonthCalendarState extends State<DiaryMonthCalendar> {
  late DateTime _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);
  Set<String> _eventDates = {};
  Set<String> _entryDates = {};
  bool _loading = true;

  static const List<String> _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final events = await DatabaseManager().getEventDatesForMonth(widget.patientUuid, _month.year, _month.month);
    final entries = await DatabaseManager().getDiaryEntryDatesForMonth(widget.patientUuid, _month.year, _month.month);
    if (!mounted) return;
    setState(() {
      _eventDates = events;
      _entryDates = entries;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadMonth();
  }

  String _dateKey(int day) =>
      '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // DateTime.weekday is 1=Monday..7=Sunday; this grid starts on Sunday, so shift so
    // Sunday=0..Saturday=6.
    final int firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final DateTime today = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Symbols.chevron_left), onPressed: () => _changeMonth(-1)),
              Text('${_monthNames[_month.month - 1]} ${_month.year}', style: CarbonTheme.carbonHeadingTextStyle),
              IconButton(icon: const Icon(Symbols.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: _weekdayLabels
                        .map((d) => Expanded(child: Center(child: Text(d, style: CarbonTheme.carbonHelperTextStyle))))
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < firstWeekday) return const SizedBox.shrink();
                        final int day = index - firstWeekday + 1;
                        final String key = _dateKey(day);
                        final bool hasEvent = _eventDates.contains(key);
                        final bool hasEntry = _entryDates.contains(key);
                        final bool isToday = today.year == _month.year && today.month == _month.month && today.day == day;

                        return InkWell(
                          onTap: () => widget.onDaySelected(DateTime(_month.year, _month.month, day)),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: isToday ? Border.all(color: carbonColorBorderInteractive, width: 1.5) : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$day', style: CarbonTheme.carbonTextStyle),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (hasEvent) _dot(carbonColorSupportInfo),
                                    if (hasEvent && hasEntry) const SizedBox(width: 3),
                                    if (hasEntry) _dot(carbonColorSupportSuccess),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
