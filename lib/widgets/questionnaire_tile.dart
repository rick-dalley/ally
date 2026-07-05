import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/date_time_utilities.dart';
import '../app_theme.dart';

class QuestionnaireTile extends StatelessWidget {
  final String assessmentName;
  final String patientId;
  final String subtitle;
  final String template;
  final String? scoreGuidePath;
  final bool isCompleted;
  final DateTime? dateTaken; // Added
  final String description; // Added for the info modal
  final Widget Function(String, Map<String, dynamic>, ScrollController) builder;
  final Function(
    BuildContext,
    String,
    String,
    String,
    String?,
    bool,
    Widget Function(String, Map<String, dynamic>, ScrollController),
  )
  onLaunch;

  const QuestionnaireTile({
    super.key,
    required this.assessmentName,
    required this.patientId,
    required this.subtitle,
    required this.template,
    this.scoreGuidePath,
    required this.isCompleted,
    this.dateTaken,
    this.description = "No information available.",
    required this.builder,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: isCompleted ? AppTheme.clinicalCyan : AppTheme.cardBorder, width: 1.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildIconSection(), _buildTextSection(context), _buildInfoSection(context)],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Icon(
          isCompleted ? Symbols.ballot : Symbols.ballot_sharp,
          color: isCompleted ? AppTheme.clinicalCyan : AppTheme.deepCharcoal,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildTextSection(BuildContext context) {
    final daysElapsed = dateTaken != null ? DateTime.now().difference(dateTaken!).inDays : null;

    return Expanded(
      child: InkWell(
        onTap: () => onLaunch(context, assessmentName, patientId, template, scoreGuidePath, isCompleted, builder),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assessmentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              if (dateTaken != null) ...[
                const SizedBox(height: 6),
                Text(
                  "Taken on: ${dateTaken!.toString().split(' ')[0]} (${DTUtilities.getRecencyString(dateTaken!)})",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return InkWell(
      onTap: () => _showInfoModal(context),
      child: const SizedBox(width: 50, child: Icon(Symbols.info, color: AppTheme.deepCharcoal, size: 24)),
    );
  }

  void _showInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assessmentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        ),
      ),
    );
  }
}
