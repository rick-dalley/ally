import 'package:flutter/material.dart';

class MetricSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedMetrics;
  final Function(List<String>) onSave;

  const MetricSelectionScreen({super.key, required this.initialSelectedMetrics, required this.onSave});

  @override
  State<MetricSelectionScreen> createState() => _MetricSelectionScreenState();
}

class _MetricSelectionScreenState extends State<MetricSelectionScreen> {
  // Master list of available metrics
  final List<String> _availableMetrics = [
    "Heart Rate",
    "Temperature"
        "Blood Pressure"
        "SpO2",
    "Weight",
    "Resting Heart Rate",
    "Sleep Times",
    "Respiration Rate",
    "Meal Times",
    "Meal Content",
    "Urination",
    "Bowel Movement",
    "Blood Glucose Monitoring", //Using a glucose meter and test strips (typically via a finger prick) to check blood sugar levels throughout the day.
    "Continuous Glucose Monitoring (CGM)", // A device with a sensor placed under the skin that records glucose levels every few minutes and can send the data to a mobile device.
  ];

  late Set<String> _selectedMetrics;

  @override
  void initState() {
    super.initState();
    _selectedMetrics = widget.initialSelectedMetrics.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tracking Metrics")),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Select the metrics you would like to track daily:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _availableMetrics.length,
              itemBuilder: (context, index) {
                final metric = _availableMetrics[index];
                final isSelected = _selectedMetrics.contains(metric);

                return InkWell(
                  onTap: () => setState(() {
                    isSelected ? _selectedMetrics.remove(metric) : _selectedMetrics.add(metric);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 15),
                        Text(metric, style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () => widget.onSave(_selectedMetrics.toList()),
              child: const Text("Save Preferences"),
            ),
          ),
        ],
      ),
    );
  }
}
