import 'package:flutter/material.dart';
import 'package:ally/screens/questionnaire_answering_screen.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/questionnaire_catalog.dart';
import '../classes/templates.dart';
import '../widgets/questionnaire_tile.dart';

// Only ever shows a questionnaire a provider actually assigned (see
// AssignQuestionnaireScreen) — there is no catalog to browse here anymore. Each tile
// disappears the moment it's answered (medical_profile_screen.dart hides this whole
// screen's entry point once nothing is left active), so in practice this list is
// almost always either empty (never reached — the tile isn't shown) or has exactly
// one or two entries.
class QuestionnairesScreen extends StatefulWidget {
  final Patient patient;

  const QuestionnairesScreen({super.key, required this.patient});
  @override
  State<StatefulWidget> createState() => QuestionnairesScreenState();
}

class QuestionnairesScreenState extends State<QuestionnairesScreen> {
  late Future<List<Map<String, dynamic>>> activeAssignments;

  @override
  void initState() {
    super.initState();
    activeAssignments = DatabaseManager().getActiveAssignedQuestionnaires(widget.patient.patientUuid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: activeAssignments,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final assignments = snapshot.data ?? [];
            if (assignments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("Nothing requested right now."),
                ),
              );
            }
            return Column(children: _buildQuestionnaireTiles(assignments));
          },
        ),
      ),
    );
  }

  List<Widget> _buildQuestionnaireTiles(List<Map<String, dynamic>> assignments) {
    return assignments
        .map((assignment) {
          final String templateId = assignment['template_id'] as String;
          final QuestionnaireCatalogEntry? entry = questionnaireCatalogEntry(templateId);
          if (entry == null) return null;
          final String assignmentId = assignment['id'] as String;
          final String providerName = assignment['provider_name'] as String;
          final String providerEmail = assignment['provider_email'] as String;

          return QuestionnaireTile(
            assessmentName: entry.name,
            patientId: widget.patient.patientUuid,
            dateTaken: null,
            description: entry.explanation,
            subtitle: entry.subTitle,
            template: entry.template,
            scoreGuidePath: entry.guide,
            isCompleted: false,
            builder: (id, data, ctrl) => QuestionnaireAnsweringScreen(
              assessmentId: data["assessmentId"],
              patientUuid: data["patientUuid"],
              scoreGuidePath: data["scoreGuidePath"],
              template: data["template"],
              isReadOnly: data['isReadOnly'],
              logic: entry.logic,
              scrollController: ctrl,
              assignedQuestionnaireId: assignmentId,
              providerName: providerName,
              providerEmail: providerEmail,
              patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
            ),
            onLaunch: (ctx, name, pid, temp, guide, readOnly, builder) {
              launchQuestionnaire(
                ctx,
                assessmentId: name,
                patientId: pid,
                templateName: temp,
                scoreGuidePath: guide,
                isReadOnly: readOnly,
                assignmentId: assignmentId,
                providerName: providerName,
                providerEmail: providerEmail,
                screenBuilder: builder,
              );
            },
          );
        })
        .whereType<Widget>()
        .toList();
  }

  Future<void> launchQuestionnaire(
    BuildContext context, {
    required String assessmentId,
    required String patientId,
    required String templateName,
    required String? scoreGuidePath,
    required bool isReadOnly,
    required String assignmentId,
    required String providerName,
    required String providerEmail,
    required Widget Function(String assessmentId, Map<String, dynamic> template, ScrollController controller)
    screenBuilder,
  }) async {
    // 1. Fetch the requested template
    Map<String, dynamic> template = await Templates.getTemplate(templateName);
    // 2. Standardized Modal Plumbing
    if (!context.mounted) return;
    // We wrap the patientUuid and the read-only flag into the context map
    final Map<String, dynamic> patientContext = {
      'assessmentId': assessmentId,
      'patientUuid': patientId, // Put it in the envelope here
      'isReadOnly': isReadOnly,
      'scoreGuidePath': scoreGuidePath,
      'template': template,
      'assignmentId': assignmentId,
      'providerName': providerName,
      'providerEmail': providerEmail,
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.zero),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.zero),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey, // Or use AppTheme.subText
                      size: 22,
                    ),
                    tooltip: "Dismiss assessment",
                    // Close the sheet  and flag a false result down to the database poker
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Expanded(
                  // Inject the specific screen
                  child: screenBuilder(assessmentId, patientContext, scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Refresh — the assignment this tile came from may have just been completed and
    // withdrawn (see QuestionnaireAnsweringScreen._submitAssessment), so re-query
    // rather than trusting the list this screen was built with.
    if (mounted) {
      setState(() {
        activeAssignments = DatabaseManager().getActiveAssignedQuestionnaires(widget.patient.patientUuid);
      });
    }
  }
}
