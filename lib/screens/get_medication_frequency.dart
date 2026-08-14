import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/app_theme.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/classes/frequency_codes.dart';
import 'package:triage/classes/medication_services.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';
import 'package:triage/widgets/carbon_style_full_button.dart';
import '../classes/listable.dart';

class GetMedicationFrequency extends StatefulWidget {
  final TextEditingController controller;
  final Function(Frequency) onFrequencySelected;

  const GetMedicationFrequency({super.key, required this.controller, required this.onFrequencySelected});

  @override
  State<GetMedicationFrequency> createState() => _GetMedicationFrequencyState();
}

class _GetMedicationFrequencyState extends State<GetMedicationFrequency> {
  bool _alert = false;
  DateTime? start;
  DateTime? end;
  DateTime? specificTime;
  String? latinRecurrence;

  bool get _shouldRecommendAlert => specificTime != null;

  @override
  void initState() {
    super.initState();
    start = DateTime.now();
    end = start?.add(const Duration(days: 30));
    latinRecurrence = FrequencyCodes.quaqueDie.latin;
    // Deferred: this page mounts mid-build as the wizard's PageView transitions to it,
    // so calling the parent's setState synchronously here would fire while the
    // framework is still building (a "setState called during build" crash). Posting
    // it for after the frame finishes is the standard fix.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emitFrequency();
    });
  }

  void _emitFrequency() {
    widget.onFrequencySelected(
      Frequency(latinRecurrence: latinRecurrence, start: start, end: end, specificTime: specificTime, alert: _alert),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: AppTheme.onPrimaryColor,
        child: Column(
          children: [
            Text("Frequency", style: CarbonTheme.carbonHeadingTextStyle),
            Text("Set the time and frequency that you must take this medication"),
            SizedBox(height: CarbonSpacing.wide.height),
            // Using a conditional to prevent build errors before data arrives
            //
            CarbonDropdown(
              label: "Frequency",
              helperText: "Check the code for frequency on the label of you medication, or choose it if you know it",
              placeholder: "Select the frequency",
              items: FrequencyCodes.values,
              value: FrequencyCodes.quaqueDie,
              onChanged: (Listable val) {
                setState(() {
                  FrequencyCodes frequencyCode = val as FrequencyCodes;
                  latinRecurrence = frequencyCode.latin;
                });
                _emitFrequency();
              },
            ),
            SizedBox(height: CarbonSpacing.wide.height),
            Row(
              children: [
                Expanded(
                  child: CarbonFullButton(
                    icon: Symbols.calendar_clock,
                    style: CarbonButtonStyle.tertiary,
                    label: start != null ? "Start: ${start.toString().split(' ')[0]}" : "Start Date",
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => start = date);
                        _emitFrequency();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CarbonFullButton(
                    icon: Symbols.calendar_clock,
                    style: CarbonButtonStyle.tertiary,
                    label: end != null ? "End: ${end.toString().split(' ')[0]}" : "End Date",
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: end ?? DateTime.now(),
                        firstDate: start ?? DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => end = date);
                        _emitFrequency();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: Text("Time", style: CarbonTheme.carbonLabelTextStyle),
              trailing: IconButton(icon: const Icon(Symbols.schedule), onPressed: _pickTime),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Text(
                  specificTime != null
                      ? "Selected: ${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}"
                      : "6:00pm",
                  style: CarbonTheme.carbonTextStyle,
                ),
              ),
            ),

            const Divider(),

            Container(
              color: _shouldRecommendAlert && !_alert ? Colors.amber.withValues(alpha: 0.1) : null,
              child: SwitchListTile(
                title: const Text("Enable Medication Alerts"),
                subtitle: _shouldRecommendAlert ? const Text("Recommended for specific times") : null,
                value: _alert,
                onChanged: (val) {
                  setState(() => _alert = val);
                  _emitFrequency();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        specificTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, time.hour, time.minute);
      });
      _emitFrequency();
    }
  }
}
