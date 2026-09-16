import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/patient_diary.dart';
import '../classes/patient_life_event.dart';
import '../classes/provider.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';
import '../widgets/diary_month_calendar.dart';
import '../widgets/life_event_sheet.dart';

// Opens on today. Prev/next arrows flip a day at a time; a calendar toggle switches to
// a month grid for jumping further. Auto-pulled events (meds, appointments, symptoms,
// mood, tests) always show for whichever day is currently displayed — they're memory
// prompts, not a report — but nothing is ever saved unless the patient actually writes
// something: leaving a day with empty text saves nothing, and clearing previously
// saved text back to empty deletes that day's entry outright.
//
// Life events sit in that same list but are the exception to "auto-pulled": the patient
// wrote them, here or from a mood check-in, so they're the only rows that can be tapped
// to correct or delete.
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
      ...eventRows['careOrders']!.map(DiaryDayEvent.careOrder),
      ...eventRows['symptoms']!.map(DiaryDayEvent.symptom),
      ...eventRows['moods']!.map(DiaryDayEvent.mood),
      ...eventRows['tests']!.map(DiaryDayEvent.test),
      ...eventRows['lifeEvents']!.map(DiaryDayEvent.lifeEvent),
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

  // Adds an event to whichever day is on screen — the reason this lives here and not
  // only in the mood check-in. Nobody logs everything as it happens, and a diary you
  // can't back-fill is a diary that stops matching the week you actually had.
  Future<void> _addLifeEvent() async {
    await _saveIfNeeded();
    if (!mounted) return;
    final bool changed = await showLifeEventSheet(
      context,
      patientUuid: widget.user.patientUuid,
      day: _currentDate,
    );
    if (changed && mounted) await _loadDay();
  }

  // Only ever reached from a life-event row — every other row in this list is derived
  // from a clinical record that has its own screen to be corrected on.
  Future<void> _editLifeEvent(int id) async {
    final rows = await DatabaseManager().getLifeEventsForDay(widget.user.patientUuid, _currentDate);
    final match = rows.where((r) => r['id'] == id).toList();
    if (match.isEmpty || !mounted) return;
    final bool changed = await showLifeEventSheet(
      context,
      patientUuid: widget.user.patientUuid,
      day: _currentDate,
      existing: PatientLifeEvent.fromRow(match.first),
    );
    if (changed && mounted) await _loadDay();
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

  // Emails whatever's currently in the box for this day — not necessarily saved yet,
  // same as tapping Save Entry would capture. Only providers with an email on file
  // are offered, since there's nowhere to send it otherwise.
  Future<void> _emailToProvider() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nothing written today yet.")));
      return;
    }
    final rows = await DatabaseManager().getProviders(widget.user.patientUuid);
    final providers = rows.map(Provider.fromJson).where((p) => (p.email ?? '').isNotEmpty).toList();
    if (!mounted) return;
    if (providers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No care provider has an email on file yet.")));
      return;
    }
    final Provider? chosen = await showModalBottomSheet<Provider>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Email today's diary entry to", style: CarbonTheme.carbonLabelTextStyle),
            ),
            ...providers.map(
              (p) => ListTile(
                title: Text('${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()),
                subtitle: Text(p.email!),
                onTap: () => Navigator.of(sheetContext).pop(p),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: chosen.email,
      queryParameters: {'subject': 'Diary entry — ${_formatHeaderDate(_currentDate)}', 'body': text},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open an email app.")));
    }
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
            if (!_showingCalendar)
              IconButton(
                icon: const Icon(Symbols.forward_to_inbox),
                tooltip: "Email to a care provider",
                onPressed: _emailToProvider,
              ),
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
          const SizedBox(height: 12),
        ],
        // Outside the isNotEmpty guard on purpose: a day with nothing auto-recorded is
        // exactly the day most likely to need something written down by hand.
        Align(
          alignment: Alignment.centerLeft,
          child: CarbonCompactButton(
            icon: Symbols.add,
            label: "Add something that happened",
            style: CarbonButtonStyle.ghost,
            onTap: _addLifeEvent,
          ),
        ),
        const SizedBox(height: 24),
        CarbonTextInput(
          label: "Your notes",
          helperText: "Write anything — thoughts, how you felt, what happened and how it left you.",
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

  // Life-event rows are the only tappable ones — they're the only thing here the
  // patient wrote, so they're the only thing this screen has any business editing or
  // deleting. The mood color, when there is one, is carried by the icon rather than
  // restated in text; the sentiment face already says it.
  Widget _buildEventTile(DiaryDayEvent event) {
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(event.icon, size: 20, color: event.accent),
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

    if (event.lifeEventId == null) return row;
    return InkWell(onTap: () => _editLifeEvent(event.lifeEventId!), child: row);
  }
}
