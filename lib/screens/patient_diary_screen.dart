import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/patient_diary.dart';
import '../widgets/carbon_button_compact.dart';
import '../widgets/carbon_style_textbox.dart';
import '../widgets/diary_month_calendar.dart';

// Opens on today. Prev/next arrows flip a day at a time; a calendar toggle switches to
// a month grid for jumping further. Auto-pulled events (meds, appointments, symptoms,
// mood, tests) always show for whichever day is currently displayed — they're memory
// prompts, not a report — but nothing is ever saved unless the patient actually writes
// something: leaving a day with empty text saves nothing, and clearing previously
// saved text back to empty deletes that day's entry outright.
class PatientDiaryScreen extends StatefulWidget {
  final Patient user;
  const PatientDiaryScreen({super.key, required this.user});

  @override
  State<PatientDiaryScreen> createState() => _PatientDiaryScreenState();
}

class _PatientDiaryScreenState extends State<PatientDiaryScreen> {
  late DateTime _currentDate = _dateOnly(DateTime.now());
  bool _showingCalendar = false;
  bool _loading = true;
  List<DiaryDayEvent> _events = [];
  final TextEditingController _textController = TextEditingController();
  String _lastSavedText = '';

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
  bool get _isToday => _currentDate == _dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  @override
  void dispose() {
    // Best-effort — fires the save without blocking teardown. Every other navigation
    // path (arrows, calendar toggle, back button) already awaits _saveIfNeeded
    // properly; this only covers whatever route pop this widget doesn't intercept.
    _saveIfNeeded();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadDay() async {
    setState(() => _loading = true);
    final entryRow = await DatabaseManager().getDiaryEntry(widget.user.patientUuid, _currentDate);
    final eventRows = await DatabaseManager().getDayEvents(widget.user.patientUuid, _currentDate);

    final List<DiaryDayEvent> events = [
      ...eventRows['doses']!.map(DiaryDayEvent.medicationDose),
      ...eventRows['appointments']!.map(DiaryDayEvent.appointment),
      ...eventRows['symptoms']!.map(DiaryDayEvent.symptom),
      ...eventRows['moods']!.map(DiaryDayEvent.mood),
      ...eventRows['tests']!.map(DiaryDayEvent.test),
    ]..sort((a, b) => (a.time ?? DateTime(0)).compareTo(b.time ?? DateTime(0)));

    final String text = entryRow != null ? (entryRow['content'] as String? ?? '') : '';
    if (!mounted) return;
    setState(() {
      _events = events;
      _textController.text = text;
      _lastSavedText = text;
      _loading = false;
    });
  }

  // Saves only if the text actually changed since load — an unmodified existing entry
  // (or a still-empty day) shouldn't trigger a write on every navigation.
  Future<void> _saveIfNeeded() async {
    final String text = _textController.text.trim();
    if (text == _lastSavedText.trim()) return;
    if (text.isEmpty) {
      await DatabaseManager().deleteDiaryEntry(widget.user.patientUuid, _currentDate);
    } else {
      await DatabaseManager().saveDiaryEntry(widget.user.patientUuid, _currentDate, text);
    }
    _lastSavedText = text;
  }

  Future<void> _changeDay(DateTime newDate) async {
    await _saveIfNeeded();
    if (!mounted) return;
    setState(() => _currentDate = newDate);
    await _loadDay();
  }

  Future<void> _toggleCalendar() async {
    await _saveIfNeeded();
    if (!mounted) return;
    setState(() => _showingCalendar = !_showingCalendar);
  }

  String _formatHeaderDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveIfNeeded();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Patient Diary", style: CarbonTheme.carbonLabelTextStyle),
          backgroundColor: AppTheme.lightTheme.canvasColor,
          actions: [
            IconButton(
              icon: Icon(_showingCalendar ? Symbols.calendar_view_day : Symbols.calendar_month),
              tooltip: _showingCalendar ? "Day view" : "Calendar view",
              onPressed: _toggleCalendar,
            ),
          ],
        ),
        body: _showingCalendar
            ? DiaryMonthCalendar(
                patientUuid: widget.user.patientUuid,
                initialMonth: _currentDate,
                onDaySelected: (date) {
                  setState(() {
                    _currentDate = _dateOnly(date);
                    _showingCalendar = false;
                  });
                  _loadDay();
                },
              )
            : _buildDayView(),
      ),
    );
  }

  Widget _buildDayView() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Symbols.chevron_left),
              onPressed: () => _changeDay(_currentDate.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: Text(
                _formatHeaderDate(_currentDate),
                textAlign: TextAlign.center,
                style: CarbonTheme.carbonHeadingTextStyle,
              ),
            ),
            IconButton(
              icon: const Icon(Symbols.chevron_right),
              onPressed: _isToday ? null : () => _changeDay(_currentDate.add(const Duration(days: 1))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_events.isNotEmpty) ...[
          Text("What happened today", style: CarbonTheme.carbonLabelTextStyle),
          const SizedBox(height: 8),
          ..._events.map(_buildEventTile),
          const SizedBox(height: 24),
        ],
        CarbonTextInput(
          label: "Your notes",
          helperText: "Write anything — thoughts, how you felt, what happened.",
          controller: _textController,
          maxLines: 8,
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        CarbonCompactButton(
          icon: Symbols.check,
          label: "Save Entry",
          style: CarbonButtonStyle.primary,
          onTap: () => _saveIfNeeded(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventTile(DiaryDayEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(event.icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: CarbonTheme.carbonTextStyle),
                if (event.subtitle.isNotEmpty)
                  Text(event.subtitle, style: CarbonTheme.carbonHelperTextStyle),
              ],
            ),
          ),
          if (event.time != null)
            Text(
              '${event.time!.hour.toString().padLeft(2, '0')}:${event.time!.minute.toString().padLeft(2, '0')}',
              style: CarbonTheme.carbonHelperTextStyle,
            ),
        ],
      ),
    );
  }
}
