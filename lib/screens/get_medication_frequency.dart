import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/app_theme.dart';
import 'package:triage/classes/carbon_style_constants.dart';
import 'package:triage/classes/frequency_codes.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';
import 'package:triage/widgets/carbon_style_full_button.dart';
import '../classes/medication_services.dart';

class GetMedicationFrequency extends StatefulWidget {
  final TextEditingController controller;
  final Function(Frequency) onAddFrequency;

  const GetMedicationFrequency({super.key, required this.controller, required this.onAddFrequency});

  @override
  State<GetMedicationFrequency> createState() => _GetMedicationFrequencyState();
}

class _GetMedicationFrequencyState extends State<GetMedicationFrequency> {
  bool _alert = false;
  DateTime? start;
  DateTime? end;
  DateTime? specificTime;
  String? latinRecurrence;
  List<FrequencyCode> frequencyCodes = [];

  bool get _shouldRecommendAlert => specificTime != null;

  @override
  void initState() {
    super.initState();
    start = DateTime.now();
    end = start?.add(const Duration(days: 30));
    _loadCodes(); // Call a separate method
  }

  // Separate method to handle async work
  Future<void> _loadCodes() async {
    final codes = await FrequencyCodeService.getCodes();
    if (mounted) {
      setState(() => frequencyCodes = codes);
    }
  }

  void _update() {
    widget.onAddFrequency(
      Frequency(alert: _alert, start: start, end: end, specificTime: specificTime, latinRecurrence: latinRecurrence),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Text("Frequency", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
            Text("Set the time and frequency that you must take this medication"),
            SizedBox(height: CarbonSpacing.wide.height),
            // Using a conditional to prevent build errors before data arrives
            frequencyCodes.isEmpty
                ? const CircularProgressIndicator()
                : CarbonDropdown(
                    label: "Recurrence",
                    helperText:
                        "Check the code for frequency on the label of you medication, or choose it if you know it",
                    items: frequencyCodes.map((f) {
                      return DropdownMenuItem<String>(
                        value: f.code,
                        child: SizedBox(
                          // Set a width or use MediaQuery to dynamically constrain it
                          // relative to the screen width, or just wrap in a Container
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Text(
                            "${f.code} - ${f.english}",
                            overflow: TextOverflow.ellipsis, // Ensures text cuts off cleanly
                            maxLines: 1, // Optional: keeps it to one line
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => latinRecurrence = val);
                      _update();
                    },
                  ),
            SizedBox(height: CarbonSpacing.wide.height),
            Row(
              children: [
                Expanded(
                  child: CarbonFullButton(
                    icon: Symbols.calendar_clock,
                    color: AppColors.peacockBlue,
                    label: start != null ? "Start: ${start.toString().split(' ')[0]}" : "Start Date",
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => start = date);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CarbonFullButton(
                    icon: Symbols.calendar_clock,
                    color: AppColors.peacockBlue,
                    label: end != null ? "End: ${end.toString().split(' ')[0]}" : "End Date",
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: end ?? DateTime.now(),
                        firstDate: start ?? DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => end = date);
                    },
                  ),
                ),
              ],
            ),

            ListTile(
              title: const Text("Specific Time"),
              trailing: IconButton(icon: const Icon(Symbols.schedule), onPressed: _pickTime),
              subtitle: Text(
                specificTime != null
                    ? "Selected: ${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}"
                    : "None",
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
                  _update();
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
      _update();
    }
  }
}
