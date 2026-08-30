import 'assessment_logic.dart';

// The full set of mental-wellness instruments this app knows how to render — moved
// here (out of questionnaires_screen.dart) so both that screen and the incoming
// ally://assignQuestionnaire handler (AssignQuestionnaireScreen) can look a
// clinician-sent template_id up by the same single list, rather than keeping two
// copies of "what PHQ-9 means" in sync by hand. `id` is what travels in the
// assignment payload and matches Progressor's own hardcoded picker — see
// AssignQuestionnaireScreen's doc comment for why that duplication is fine.
class QuestionnaireCatalogEntry {
  final String id;
  final String name;
  final String subTitle;
  final String explanation;
  final String template;
  final AssessmentLogic logic;
  final String? guide;

  const QuestionnaireCatalogEntry({
    required this.id,
    required this.name,
    required this.subTitle,
    required this.explanation,
    required this.template,
    required this.logic,
    this.guide,
  });
}

final List<QuestionnaireCatalogEntry> questionnaireCatalog = [
  QuestionnaireCatalogEntry(
    id: "PHQ-9",
    name: "PHQ-9",
    subTitle: "Patient Health Questionnaire 9",
    explanation:
        "The PHQ-9 (Patient Health Questionnaire-9) is a standardized, 9-item self-report tool used by clinicians to screen for, diagnose, and monitor the severity of depression. It evaluates symptoms over the past two weeks, such as depressed mood, sleep disturbances, and fatigue",
    template: "phq-9.json",
    logic: PHQ9Logic(),
    guide: 'assets/questions/phq9_score_guide.json',
  ),
  QuestionnaireCatalogEntry(
    id: "GAD-7",
    name: "GAD-7",
    subTitle: "General Anxiety Disorder-7",
    explanation:
        "The GAD-7 is a 7-item clinical questionnaire used to screen for Generalized Anxiety Disorder and assess its severity. By rating symptoms over the past two weeks, individuals receive a score from 0 to 21. You can complete an interactive version on the MDCalc website.",
    template: "gad-7.json",
    logic: GAD7Logic(),
    guide: 'assets/questions/gad7_score_guide.json',
  ),
  QuestionnaireCatalogEntry(
    id: "C-SSRS",
    name: "C-SSRS",
    subTitle: "Columbia-Suicide Severity Rating Scale",
    explanation:
        "The Columbia-Suicide Severity Rating Scale (C-SSRS) is a widely used, evidence-based questionnaire designed to screen for suicide risk. It assesses the full spectrum of suicidal ideation (thoughts of suicide) and behavior (preparatory acts, aborted attempts, or actual attempts) to help clinicians determine the appropriate level of care",
    template: "c-ssrs.json",
    logic: CSSRSLogic(),
    guide: null,
  ),
  QuestionnaireCatalogEntry(
    id: "DAST-10",
    name: "DAST-10",
    subTitle: "Drug Abuse Screening Test 10",
    explanation:
        "The DAST-10 provides a brief, simple, practical, but valid method for identifying individuals who are abusing psychoactive drugs. It also yields a quantitative index score of the degree of problems related to drug use and misuse. The DAST-10 obtains no information on the various types of drugs used, or on the frequency or duration of the drug use. It includes a question regarding multiple drug use, and some of the types of problems caused by drug use/abuse are surveyed. This includes marital-family relationships, legal, medical symptoms and physical health conditions. An examination of the individual item responses indicates the specific life problem areas.",
    template: "dast-10.json",
    logic: DAST10Logic(),
    guide: 'assets/questions/dast10_score_guide.json',
  ),
  QuestionnaireCatalogEntry(
    id: "ASRS-V1.1",
    name: "ASRS-V1.1",
    subTitle: "Adult ADHD Self-Report Scale (ASRS) version 1.1",
    explanation:
        "The Adult ADHD Self-Report Scale (ASRS) version 1.1 is a diagnostic tool designed for the assessment of Attention-Deficit/Hyperactivity Disorder (ADHD) in adults; developed in collaboration between the World Health Organization (WHO) and researchers at Harvard Medical School.",
    template: "asrs.json",
    logic: ASRS11Logic(),
    guide: 'assets/questions/asrs_score_guide.json',
  ),
  QuestionnaireCatalogEntry(
    id: "PCL-5",
    name: "PCL-5",
    subTitle: "PTSD Checklist 5",
    explanation:
        "The PCL-5 (Posttraumatic Stress Disorder Checklist for DSM-5) is a widely used, 20-item self-report questionnaire designed to screen for PTSD and measure symptom severity over the past month. It asks you to rate how much you've been bothered by specific problems stemming from a specific stressful event",
    template: "pcl-5.json",
    logic: PCL5Logic(),
    guide: 'assets/questions/pcl5_score_guide.json',
  ),
];

QuestionnaireCatalogEntry? questionnaireCatalogEntry(String id) {
  for (final entry in questionnaireCatalog) {
    if (entry.id == id) return entry;
  }
  return null;
}
