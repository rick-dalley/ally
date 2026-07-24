import 'package:flutter/material.dart';

import '../app_theme.dart';

class VitalsDashboard extends StatefulWidget {
  final Map<String, TextEditingController> controllers;

  const VitalsDashboard({super.key, required this.controllers});

  @override
  State<VitalsDashboard> createState() => _VitalsDashboardState();
}

class _VitalsDashboardState extends State<VitalsDashboard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blueGrey.shade900,
      child: Row(
        children: [
          _buildField("Temp", widget.controllers['temp']!),
          _buildField("HR", widget.controllers['hr']!),
          _buildField("BP", widget.controllers['bp']!),
          _buildField("RR", widget.controllers['rr']!),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          style: TextStyle(color: AppTheme.onPrimaryColor, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: AppTheme.onPrimaryColor, fontSize: 12),
            border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.onPrimaryColor)),
          ),
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }
}
