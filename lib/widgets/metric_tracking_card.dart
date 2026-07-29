import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/listable.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';
import 'package:triage/widgets/carbon_style_number_edit.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';
import '../app_theme.dart';
import '../classes/carbon_theme_constants.dart';

enum JourneySupports implements Listable {
  device,
  medication,
  activity,
  specialist;

  @override
  String get description {
    switch (this) {
      case JourneySupports.device:
        return "Connected BLE Device";
      case JourneySupports.medication:
        return "Associated Medication";
      case JourneySupports.activity:
        return "Physical Activity Routine";
      case JourneySupports.specialist:
        return "Assigned Care Specialist";
    }
  }

  @override
  String get label {
    switch (this) {
      case JourneySupports.device:
        return "device";
      case JourneySupports.medication:
        return "medication";
      case JourneySupports.activity:
        return "activity";
      case JourneySupports.specialist:
        return "specialist";
    }
  }
}

class MetricExpandableCard extends StatefulWidget {
  final String title;
  final String description;
  final String whyItMatters;
  final IconData categoryIcon;
  final bool isInitiallyTracked;
  final List<Map<String, dynamic>>? historicalValues;
  final Map<String, dynamic>? savedConfig;
  const MetricExpandableCard({
    super.key,
    required this.title,
    required this.description,
    required this.whyItMatters,
    required this.categoryIcon,
    this.isInitiallyTracked = false,
    this.historicalValues,
    this.savedConfig,
  });

  @override
  State<MetricExpandableCard> createState() => MetricExpandableCardState();
}

class MetricExpandableCardState extends State<MetricExpandableCard> {
  late bool isTracked;
  bool isExpanded = false;
  bool showInfoView = false; // true if opened via '?' button

  // Form states for tracking details
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _upperLimitController = TextEditingController();
  final TextEditingController _lowerLimitController = TextEditingController();
  bool showMedicalLimits = false;
  bool showHealthyLimits = false;
  String? linkedResource;
  late List<Map<String, dynamic>> history;
  late Map<String, dynamic> config;

  @override
  void initState() {
    super.initState();
    history = widget.historicalValues ?? [];
    config = widget.savedConfig ?? {};
    isTracked = widget.isInitiallyTracked;
  }

  @override
  void dispose() {
    _targetController.dispose();
    _upperLimitController.dispose();
    _lowerLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = CarbonTheme.getTileBorderColor(CarbonTileStyle.expandable, isTracked);
    return Card(
      elevation: 0,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      color: carbonColorButtonTertiary,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(border: Border.all(color: borderColor, width: 1)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Row: Icon on left, Title, Checkbox on far right
            Row(
              children: [
                SizedBox(width: 16.0),
                Icon(widget.categoryIcon, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.title, style: CarbonTheme.carbonTextStyle)),
                if (!isTracked)
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: Checkbox(
                      value: isTracked,
                      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
                      onChanged: (val) {
                        setState(() {
                          isTracked = val ?? false;
                          if (isTracked) {
                            isExpanded = true;
                            showInfoView = false;
                          }
                        });
                      },
                    ),
                  ),
              ],
            ),

            // Second Line: Description on left, HLC or '?' bubble on right, and the arrow on the far right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  if (isTrackerActiveButCollapsed())
                    _buildHlcBubblePlaceholder()
                  else
                    InkWell(
                      onTap: () {
                        setState(() {
                          isExpanded = true;
                          showInfoView = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade600)),
                        child: const Text("?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                        if (!isExpanded) showInfoView = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Symbols.arrow_downward, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Body Section (Appears below the second line when expanded)
            if (isExpanded) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(height: 1, thickness: 1)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: showInfoView ? _buildInfoContent() : _buildTrackingDetailsContent(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool isTrackerActiveButCollapsed() {
    return isTracked && !isExpanded;
  }

  Widget _buildHlcBubblePlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: const Text("H: -- | L: -- | C: --", style: TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  Widget _buildInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        CarbonTextInput(label: 'Why It Matters'),
        const SizedBox(height: 8),
        Text(widget.whyItMatters, style: CarbonTheme.carbonTextStyle),
        const SizedBox(height: 16),
        Text("Doctor Consultation Advice", style: CarbonTheme.carbonTextStyle),
        const SizedBox(height: 8),
        Text(
          "If you believe this metric is clinically relevant to your baseline or personal health journey, please consult your primary physician or specialist before starting active recording.",
          style: CarbonTheme.carbonTextStyle,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  isExpanded = false;
                  showInfoView = false;
                });
              },
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 12),
            CarbonButton(
              onPressed: () {
                setState(() {
                  isTracked = true;
                  showInfoView = false;
                });
              },
              label: 'Track',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: CarbonTheme.getTileColor(CarbonTileStyle.base),
            border: Border.all(color: CarbonTheme.getTileBorderColor(CarbonTileStyle.base, false)),
          ),
          child: Center(
            child: Text(
              "Trend Graph (Empty)\nCurve fit & data points will appear as values are tracked.",
              textAlign: TextAlign.center,
              style: CarbonTheme.carbonHintTextStyle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CarbonNumberInput(controller: _targetController, label: 'Target Value'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CarbonNumberInput(controller: _upperLimitController, label: 'Upper Limit (Alarm)'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CarbonNumberInput(controller: _lowerLimitController, label: 'Lower Limit (Alarm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text("Display Medical Set Limits", style: TextStyle(fontSize: 13)),
          value: showMedicalLimits,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) => setState(() => showMedicalLimits = val ?? false),
        ),
        CheckboxListTile(
          title: const Text("Display Universally Accepted Healthy Limits", style: TextStyle(fontSize: 13)),
          value: showHealthyLimits,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) => setState(() => showHealthyLimits = val ?? false),
        ),
        const SizedBox(height: 12),
        CarbonDropdown<JourneySupports>(
          label: 'Link Journey Support',
          items: JourneySupports.values,
          onChanged: (value) {},
          value: JourneySupports.values.first,
        ),
      ],
    );
  }
}
