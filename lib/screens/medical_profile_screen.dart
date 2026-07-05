import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/screens/observations_screen.dart';
import 'package:triage/screens/physical_health.dart';
import 'package:triage/widgets/carbon_style_action_tile.dart';
import 'package:triage/widgets/questionnaire_tile.dart';

import '../app_theme.dart';
import '../classes/assessment_logic.dart';
import '../classes/patient.dart';
import '../classes/templates.dart';
import 'immunization_screen.dart';
import 'observation.dart';

class MedicalProfileScreen extends StatefulWidget {
  final Patient householdMember;

  const MedicalProfileScreen({super.key, required this.householdMember});

  @override
  State<MedicalProfileScreen> createState() => MedicalProfileScreenState();
}

class MedicalProfileScreenState extends State<MedicalProfileScreen> {
  late Future<Map<String, CompletedQuestionnaire>> completedQuestionnaires;

  @override
  void initState() {
    super.initState();
    // Initialize the future once
    completedQuestionnaires = DatabaseManager().getCompletedAssessments(widget.householdMember.patientUuid);
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

            final Map<String, CompletedQuestionnaire> completed = snapshot.data ?? {};

            return Column(
              children: [
                // HEADER AREA (Fixed)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "PROFILE",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.deepLogicViolet,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
                              onPressed: () => Navigator.pop(context), // Dismisses the screen
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Complete the details of your current health status by completing these forms and taking these assessments.",
                  ),
                ),

                // SCROLLABLE LIST AREA (Flexible/Expanded)
                Expanded(
                  child: ListView(
                    // Use a Physics that feels natural on both iOS and Android
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    children: [
                      _buildSectionHeader("Checklists"),
                      CarbonActionTile(
                        title: "Existing Medical Conditions",
                        subTitle: "Review & Update",
                        icon: Symbols.conditions,
                        outlineIcon: Symbols.conditions_sharp,
                        onTap: () => _launchPhysicalHealthChecklist(context, widget.householdMember.patientUuid),
                      ),
                      CarbonActionTile(
                        title: "Medical Diary",
                        subTitle: "Observations about my health journey",
                        icon: Symbols.clinical_notes,
                        outlineIcon: Symbols.clinical_notes_sharp,
                        onTap: () => _launchObservationsModal(context),
                      ),
                      CarbonActionTile(
                        title: "Immunizations",
                        subTitle: "Immunization shots recommended in my locality",
                        icon: Symbols.vaccines,
                        outlineIcon: Symbols.vaccines_sharp,
                        onTap: () => _launchImmunizationModal(context, widget.householdMember),
                      ),
                      _buildSectionHeader("Mental Health Questionnaires"),
                      ..._buildQuestionnaireTiles(completed),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper to consolidate the QuestionnaireTile list
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
            patientId: widget.householdMember.patientUuid,
            dateTaken: completed[cfg["name"]]?.when,
            description: cfg["explanation"],
            subtitle: cfg["subTitle"], // Add specific subtitles per config if needed
            template: cfg["template"],
            scoreGuidePath: cfg["guide"],
            isCompleted: completed[cfg["name"]]!.completed,
            builder: (id, data, ctrl) => QuestionnaireSelectorScreen(
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

  // Helper to keep the build method clean
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: AppTheme.deepCharcoal, letterSpacing: 1.1),
      ),
    );
  }

  Future<void> _launchPhysicalHealthChecklist(BuildContext context, String patientUuid) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      useSafeArea: true, // Respects the device notch and safe areas
      backgroundColor: AppTheme.clinicalWhite,
      // Set to zero for the strict, sharp-cornered Carbon aesthetic
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Column(
          children: [
            // Header: Consistent with your other Carbon-style modals
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.grey, size: 28),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content: Expanded to fill the remaining vertical space
            Expanded(
              child: PhysicalHealthAssessment(
                patientUuid: patientUuid,
                // Pass a ScrollController if your assessment needs to manage scrolling
                scrollController: ScrollController(),
              ),
            ),
          ],
        );
      },
    );

    if (mounted && result == true) {
      setState(() {
        completedQuestionnaires = DatabaseManager().getCompletedAssessments(patientUuid);
      });
    }
  }

  Future<void> _launchObservationsModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Ensure the background is consistent with your theme
      backgroundColor: AppTheme.clinicalWhite,
      // Explicitly set to zero to override the default Material rounding
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Container(
          // Constrain height if it's not a full-screen sheet
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: AppTheme.clinicalWhite,
            borderRadius: BorderRadius.zero, // Sharp corners
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pull bar handle indicator
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                    ),
                    // Dismiss Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Symbols.close, color: Colors.grey, size: 22),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: ObservationScreen(patientUuid: widget.householdMember.patientUuid)),
            ],
          ),
        );
      },
    );
  }

  void _launchImmunizationModal(BuildContext context, Patient householdMember) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ✅ Prevents accidental drag-down dismissals on the background area
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: false, // ✅ Smooth, non-snapping fluid track
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered pull bar handle indicator
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                      // ✅ Unified Top-Right Dismiss Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  // ✅ Pass the controller into the screen
                  child: ImmunizationScreen(householdMember: householdMember),
                ),
              ],
            ),
          );
        },
      ),
    );
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
            decoration: const BoxDecoration(color: AppTheme.clinicalWhite, borderRadius: BorderRadius.zero),
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
                    // Closes the sheet instantly and flags a false result down to your database poker
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Expanded(
                  // 3. Inject the specific screen here
                  child: screenBuilder(assessmentId, patientContext, scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {
        completedQuestionnaires = DatabaseManager().getCompletedAssessments(
          widget.householdMember.patientUuid,
        ); // This 'pokes' the UI to refresh icons
      });
    }
  }
}
