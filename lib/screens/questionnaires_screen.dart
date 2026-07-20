import 'package:flutter/material.dart';
import 'package:triage/screens/questionnaire_answering_screen.dart';

import '../app_theme.dart';
import '../classes/assessment_logic.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/templates.dart';
import '../widgets/questionnaire_tile.dart';

class QuestionnairesScreen extends StatefulWidget {
  final Patient patient;

  const QuestionnairesScreen({super.key, required this.patient});
  @override
  State<StatefulWidget> createState() => QuestionnairesScreenState();
}

class QuestionnairesScreenState extends State<QuestionnairesScreen> {
  late Future<Map<String, CompletedQuestionnaire>> completedQuestionnaires;
  late Map<String, CompletedQuestionnaire> completed;
  @override
  void initState() {
    super.initState();
    // Initialize the future once
    completedQuestionnaires = DatabaseManager().getCompletedAssessments(widget.patient.patientUuid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,

      body: SafeArea(
        child: FutureBuilder<Map<String, CompletedQuestionnaire>>(
          future: completedQuestionnaires,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            completed = snapshot.data ?? {};
            return Column(children: [..._buildQuestionnaireTiles(completed)]);
          },
        ),
      ),
    );
  }

  List<Widget> _buildQuestionnaireTiles(Map<String, CompletedQuestionnaire> completed) {
    final List<Map<String, dynamic>> configs = [
      {
        "name": "PHQ-9",
        "subTitle": "Patient Health Questionnaire 9",
        "explanation":
            "The PHQ-9 (Patient Health Questionnaire-9) is a standardized, 9-item self-report tool used by clinicians to screen for, diagnose, and monitor the severity of depression. It evaluates symptoms over the past two weeks, such as depressed mood, sleep disturbances, and fatigue",
        "template": "phq-9.json",
        "logic": PHQ9Logic(),
        "guide": 'assets/questions/phq9_score_guide.json',
      },
      {
        "name": "GAD-7",
        "subTitle": "General Anxiety Disorder-7",
        "explanation":
            "The GAD-7 is a 7-item clinical questionnaire used to screen for Generalized Anxiety Disorder and assess its severity. By rating symptoms over the past two weeks, individuals receive a score from 0 to 21. You can complete an interactive version on the MDCalc website.",
        "template": "gad-7.json",
        "logic": GAD7Logic(),
        "guide": 'assets/questions/gad7_score_guide.json',
      },
      {
        "name": "C-SSRS",
        "subTitle": "Columbia-Suicide Severity Rating Scale",
        "explanation":
            "The Columbia-Suicide Severity Rating Scale (C-SSRS) is a widely used, evidence-based questionnaire designed to screen for suicide risk. It assesses the full spectrum of suicidal ideation (thoughts of suicide) and behavior (preparatory acts, aborted attempts, or actual attempts) to help clinicians determine the appropriate level of care",
        "template": "c-ssrs.json",
        "logic": CSSRSLogic(),
        "guide": null,
      },
      {
        "name": "DAST-10",
        "subTitle": "Drug Abuse Screening Test 10",
        "explanation":
            "The DAST-10 provides a brief, simple, practical, but valid method for identifying individuals who are abusing psychoactive drugs. It also yields a quantitative index score of the degree of problems related to drug use and misuse. The DAST-10 obtains no information on the various types of drugs used, or on the frequency or duration of the drug use. It includes a question regarding multiple drug use, and some of the types of problems caused by drug use/abuse are surveyed. This includes marital-family relationships, legal, medical symptoms and physical health conditions. An examination of the individual item responses indicates the specific life problem areas.",
        "template": "dast-10.json",
        "logic": DAST10Logic(),
        "guide": 'assets/questions/dast10_score_guide.json',
      },
      {
        "name": "ASRS-V1.1",
        "subTitle": "Adult ADHD Self-Report Scale (ASRS) version 1.1",
        "explanation":
            "The Adult ADHD Self-Report Scale (ASRS) version 1.1 is a diagnostic tool designed for the assessment of Attention-Deficit/Hyperactivity Disorder (ADHD) in adults; developed in collaboration between the World Health Organization (WHO) and researchers at Harvard Medical School.",
        "template": "asrs.json",
        "logic": ASRS11Logic(),
        "guide": 'assets/questions/asrs_score_guide.json',
      },
      {
        "name": "PCL-5",
        "subTitle": "PTSD Checklist 5",
        "explanation":
            "The PCL-5 (Posttraumatic Stress Disorder Checklist for DSM-5) is a widely used, 20-item self-report questionnaire designed to screen for PTSD and measure symptom severity over the past month. It asks you to rate how much you've been bothered by specific problems stemming from a specific stressful event",
        "template": "pcl-5.json",
        "logic": PCL5Logic(),
        "guide": 'assets/questions/pcl5_score_guide.json',
      },
    ];

    return configs
        .map(
          (cfg) => QuestionnaireTile(
            assessmentName: cfg["name"],
            patientId: widget.patient.patientUuid,
            dateTaken: completed[cfg["name"]]?.when,
            description: cfg["explanation"],
            subtitle: cfg["subTitle"], // Add specific subtitles per config if needed
            template: cfg["template"],
            scoreGuidePath: cfg["guide"],
            isCompleted: completed[cfg["name"]]?.completed ?? false,
            builder: (id, data, ctrl) => QuestionnaireAnsweringScreen(
              assessmentId: data["assessmentId"],
              patientUuid: data["patientUuid"],
              scoreGuidePath: data["scoreGuidePath"],
              template: data["template"],
              isReadOnly: data['isReadOnly'],
              logic: cfg["logic"],
              scrollController: ctrl,
            ),
            onLaunch: (ctx, name, pid, temp, guide, readOnly, builder) {
              launchQuestionnaire(
                ctx,
                assessmentId: name,
                patientId: pid,
                templateName: temp,
                scoreGuidePath: guide,
                isReadOnly: readOnly,
                screenBuilder: builder,
              );
            },
          ),
        )
        .toList();
  }

  Future<void> launchQuestionnaire(
    BuildContext context, {
    required String assessmentId,
    required String patientId,
    required String templateName,
    required String? scoreGuidePath,
    required bool isReadOnly,
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
    };

    final dynamic result = await showModalBottomSheet(
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

    //RE-ASSIGN the Future to force the FutureBuilder to rebuild
    final newFuture = DatabaseManager().getCompletedAssessments(widget.patient.patientUuid);

    //  Await the data
    final updatedCompleted = await newFuture;

    // Update BOTH the Future and the local Map
    if (mounted) {
      setState(() {
        completedQuestionnaires = newFuture; // Poke the FutureBuilder
        completed = updatedCompleted; // Poke the List UI
      });
    }
  }
}
