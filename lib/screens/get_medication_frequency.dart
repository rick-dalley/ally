import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/app_theme.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:triage/classes/frequency_codes.dart';
import 'package:triage/classes/medication_services.dart';
import 'package:carbon_ui/widgets/carbon_style_dropdown.dart';
import 'package:carbon_ui/widgets/carbon_style_full_button.dart';
import 'package:carbon_ui/interfaces/listable.dart';

class GetMedicationFrequency extends StatefulWidget {
  final TextEditingController controller;
  final Function(Frequency) onFrequencySelected;

  const GetMedicationFrequency({super.key, required this.controller, required this.onFrequencySelected});

  @override
  State<GetMedicationFrequency> createState() => _GetMedicationFrequencyState();
}

class _GetMedicationFrequencyState extends State<GetMedicationFrequency> {
  DateTime? start;
  DateTime? specificTime;
  String? latinRecurrence;

  @override
  void initState() {
    super.initState();
    start = DateTime.now();
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
    // Reminder configuration (channels, lead time, etc.) lives on its own wizard step
    // now, not on Frequency — `alert` here is vestigial and always false.
    widget.onFrequencySelected(
      Frequency(latinRecurrence: latinRecurrence, start: start, specificTime: specificTime, alert: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          color: AppTheme.onPrimaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Frequency", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 8),
              Text("How often do you take this?", style: CarbonTheme.carbonHintTextStyle),
              SizedBox(height: CarbonSpacing.wide.height),
              CarbonDropdown(
                label: "Frequency",
                helperText: "Check the code for frequency on the label of your medication, or choose it if you know it",
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
              CarbonFullButton(
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
              const SizedBox(height: 16.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Time", style: CarbonTheme.carbonLabelTextStyle),
                trailing: IconButton(icon: const Icon(Symbols.schedule), onPressed: _pickTime),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    specificTime != null
                        ? "Selected: ${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}"
                        : "6:00pm",
                    style: CarbonTheme.carbonTextStyle,
                  ),
                ),
              ),
            ],
          ),
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
