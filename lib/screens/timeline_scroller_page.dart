import 'package:flutter/material.dart';
import 'package:carbon_ui/carbon_ui.dart';

import '../classes/database_manager.dart';
import '../classes/patient_action.dart';
import '../classes/timeline_span.dart';

// Loads the patient's own timeline data and renders it via the shared
// CarbonTimelineScroller — this is the app-specific "owns the data" half of the split;
// the widget itself is a dumb renderer living in carbon_ui.
class TimelineScrollerPage extends StatefulWidget {
  final String patientUuid;

  const TimelineScrollerPage({super.key, required this.patientUuid});

  @override
  State<TimelineScrollerPage> createState() => _TimelineScrollerPageState();
}

class _TimelineScrollerPageState extends State<TimelineScrollerPage> {
  bool _loading = true;
  bool _isExample = false;
  List<CarbonTimelinePointEvent> points = [];
  List<CarbonTimelineSpan> availableSpans = [];
  late DateTime startTime;
  late DateTime endTime;

  @override
  void initState() {
    super.initState();
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
      final careOrderRows = await DatabaseManager().getCareOrderSpanRows(widget.patientUuid);
      final List<PeriodSpan> loadedSpans =
          [
            ...medRows.map(PeriodSpan.medication),
            ...conditionRows.map(PeriodSpan.condition),
            ...providerRows.map(PeriodSpan.provider),
            ...careOrderRows.map(PeriodSpan.careOrder),
          ]..sort((a, b) => b.startDate.compareTo(a.startDate));

      final DateTime earliest = [
        loadedActions.first.occurred,
        ...loadedSpans.map((s) => s.startDate),
      ].reduce((a, b) => a.isBefore(b) ? a : b);

      if (!mounted) return;
      setState(() {
        points = loadedActions;
        availableSpans = loadedSpans;
        startTime = earliest;
        endTime = DateTime.now();
        _isExample = false;
        _loading = false;
      });
    } else {
      final example = TimelineExampleData.build();
      if (!mounted) return;
      setState(() {
        points = example.actions;
        availableSpans = example.spans;
        startTime = example.startTime;
        endTime = example.endTime;
        _isExample = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return CarbonTimelineScroller(
      availableSpans: availableSpans,
      points: points,
      startTime: startTime,
      endTime: endTime,
      isExample: _isExample,
      exampleBannerText: "Showing example data — keep logging for about a week and this fills in with yours.",
    );
  }
}
