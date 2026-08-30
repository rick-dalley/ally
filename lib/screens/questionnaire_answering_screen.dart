import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import '../app_theme.dart';
import '../classes/assessment_logic.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/questionnaire_result_export.dart';
import '../generated/l10n.dart';
import '../widgets/likert_question.dart';

class QuestionnaireAnsweringScreen extends StatefulWidget {
  final String assessmentId;
  final String patientUuid;
  final bool isReadOnly;
  final String? scoreGuidePath;
  final Map<String, dynamic> template;
  final AssessmentLogic? logic;
  final ScrollController? scrollController;
  // Present only when this screen was opened for a clinician-assigned questionnaire
  // (see QuestionnairesScreen/AssignQuestionnaireScreen) — drives the completion
  // handoff back to that provider and withdraws the assignment. Every real call site
  // today is assigned; these stay nullable rather than required so a stray future
  // call site fails soft (no handoff, no withdrawal) instead of crashing.
  final String? assignedQuestionnaireId;
  final String? providerName;
  final String? providerEmail;
  final String? patientName;

  const QuestionnaireAnsweringScreen({
    super.key,
    required this.assessmentId,
    required this.patientUuid,
    required this.isReadOnly,
    required this.template,
    this.scoreGuidePath,
    this.logic,
    this.scrollController, // CHANGE 2: Add it to the constructor
    this.assignedQuestionnaireId,
    this.providerName,
    this.providerEmail,
    this.patientName,
  });

  @override
  QuestionnaireAnsweringScreenState createState() => QuestionnaireAnsweringScreenState();
}

class QuestionnaireAnsweringScreenState extends State<QuestionnaireAnsweringScreen> {
  Map<String, AssessmentAnswer> answers = {};
  String? selectedImpactId;
  bool isPreviousQuestionnaire = true;
  int get totalScore => answers.values.fold(0, (sum, val) => sum + val.value);
  bool _showValidationErrors = false;
  bool _isLoading = true;
  List<dynamic>? _scoreGuide;
  bool _submitted = false;
  bool _submitting = false;

  Future<void> _loadAnswers() async {
    final Map<String, String>? rawResults = await DatabaseManager().getLatestAssessmentResults(
      assessmentId: widget.assessmentId,
      patientId: widget.patientUuid,
    );

    //Initialize as a Map matching your new state definition
    Map<String, AssessmentAnswer> initialAnswers = {};

    if (rawResults != null) {
      initialAnswers = rawResults.map((key, value) {
        // Pass the raw string row straight to your clean parser constructor
        return MapEntry(key, AssessmentAnswer.fromRawString(value));
      });
    }

    if (mounted) {
      setState(() {
        answers = initialAnswers;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScoreGuide() async {
    // Only attempt to load if a path was provided
    if (widget.scoreGuidePath == null) return;

    try {
      final String response = await rootBundle.loadString(widget.scoreGuidePath!);
      final data = await json.decode(response);
      if (mounted) {
        setState(() {
          _scoreGuide = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading score guide: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    isPreviousQuestionnaire = widget.isReadOnly;
    _loadScoreGuide();
    _loadAnswers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final String instructionText = widget.template['column_headers'][0];
    final List questions = widget.template['questions_score'];
    final bool isFormComplete = widget.logic!.isComplete(answers, questions);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_submitted) {
      return Scaffold(body: SafeArea(child: _buildCompletion()));
    }

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildActionButton(isFormComplete),
        ),
      ),
      body: SafeArea(child: Column(children: [_buildHeader(instructionText), _buildQuestions(questions)])),
    );
  }

  // The only thing a patient ever sees after finishing an assigned questionnaire —
  // no score, no interpretation, just confirmation it reached their provider. See
  // _submitAssessment's doc comment for why scoring/interpretation is withheld
  // entirely rather than shown even briefly.
  Widget _buildCompletion() {
    final String who = widget.providerName ?? 'your care team';
    final String when = DateFormat('MMMM d, y \'at\' h:mm a').format(DateTime.now());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "Completed and returned to $who",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(when, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),
            CarbonButton(
              onPressed: () => Navigator.of(context).pop(true),
              label: "Done",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isFormComplete) {
    if (isPreviousQuestionnaire) {
      return Row(
        children: [
          Expanded(
            child: CarbonButton(
              onPressed: () => Navigator.of(context).pop(),
              style: CarbonButtonStyle.secondary,
              label: "Close Review",
            ),
          ),
          Expanded(
            child: CarbonButton(
              onPressed: () {
                setState(() {
                  isPreviousQuestionnaire = false; // Now editable
                  answers.clear(); // Clear past data
                  _showValidationErrors = false; // Reset errors
                });
              },
              label: "Retake",
            ),
          ),
        ],
      );
    } else {
      return CarbonButton(
        onPressed: () {
          if (!isFormComplete) {
            setState(() => _showValidationErrors = true);

            // Get the total expected count from your template
            final int totalExpected = (widget.template['questions_score'] as List).length;
            final int currentAnswered = answers.length;

            String message;
            if (currentAnswered < totalExpected) {
              // Generic: "Please answer all 10 questions."
              message = "Please answer all $totalExpected questions before finalizing.";
            } else {
              // This handles the "Impact" question or any secondary requirements
              message = "Please complete the remaining assessment fields.";
            }

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          } else {
            _submitAssessment();
          }
        },
        label: _submitting ? "Sending..." : "Save",
      );
    }
  }

  Widget _buildHeader(String instructionText) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      color: AppTheme.surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Shrink-wrap header content cleanly
        children: [
          Text(widget.template['title'], textAlign: TextAlign.center, style: AppTheme.defaultHeadingStyle),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(instructionText, style: AppTheme.defaultItalicsTextStyle),
        ],
      ),
    );
  }

  Widget _buildQuestions(List questions) {
    return Expanded(
      child: ListView.builder(
        // Crucial: This links the list scroll directly to the sheet thumb pull down
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16.0),
        // Padding moved inside the list viewport
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          bool visible = widget.logic?.isVisible(q["id"], answers) ?? true;
          final qId = q['id'];
          Widget questionTile = visible
              ? LikertQuestionTile(
                  q: q as Map<String, dynamic>,
                  template: widget.template,
                  currentAnswer: answers[qId],
                  showWarning: _showValidationErrors && !answers.containsKey(qId),
                  onChanged: isPreviousQuestionnaire
                      ? null
                      : (score) {
                          setState(() {
                            final existingText = answers[qId]?.text ?? "";
                            final isBoolText = existingText.contains("|");
                            answers[qId] = AssessmentAnswer(score, existingText, isBoolText);
                          });
                        },
                  onDescriptionChanged: isPreviousQuestionnaire
                      ? null
                      : (id, description) {
                          setState(() {
                            final existingValue = answers[qId]?.value ?? 0;
                            //Break the reference cache for text changes too
                            answers[qId] = AssessmentAnswer(existingValue, description, true);
                          });
                        },
                )
              : const SizedBox.shrink();

          // If it's the last question in the layout loop, append the footers
          if (index == questions.length - 1) {
            final impactData = widget.template['questions_impact'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                questionTile,
                if (impactData != null) _buildImpactSelector(impactData),
                _buildScoreFooter(),
                // Your scoring interpretation message renders here safely
                const SizedBox(height: 40),
              ],
            );
          }

          return questionTile;
        },
      ),
    );
  }

  Widget _buildImpactSelector(List<dynamic> options) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The instruction text from the template
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.template['questions_impact_text'] ?? "",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Vertical selection list
        Column(
          children: options.map((option) {
            final String id = option['id'];
            final String text = option['text'];
            final bool isSelected = answers.containsKey(id);

            return InkWell(
              onTap: () {
                setState(() {
                  // Clear out any previous impact selection (q10-q13)
                  for (var opt in options) {
                    answers.remove(opt['id']);
                  }
                  // Store the new one with value 0 to keep totalScore accurate
                  answers[id]?.value = 0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Mimics the paper checkbox/radio look
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.lightTheme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    // The text now has the full width to breathe
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.black : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, String>? getInterpretation() {
    // Use the injected logic if available, otherwise fallback to basic total
    if (widget.logic != null) {
      return widget.logic!.interpret(answers, _scoreGuide);
    }

    // Generic fallback if no logic is injected
    return {"summary": "Total Score: $totalScore", "action": "Consult clinical manual for interpretation."};
  }

  Future<void> _submitAssessment() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    // Convert our internal int answers to the String format required by the DB
    final Map<String, String> stringAnswers = answers.map((key, value) => MapEntry(key, value.asString()));

    try {
      // 1. Call your persistence logic
      await DatabaseManager().saveAssessmentResults(
        assessmentId: widget.assessmentId,
        patientId: widget.patientUuid, // Ensure this is passed into the widget
        answers: stringAnswers,
        isComplete: true,
      );

      // 2. If this was a clinician-requested questionnaire, hand the results back to
      // them and withdraw the assignment — the patient never sees the score computed
      // here, only that it was sent (see _buildCompletion). A future call site that
      // isn't gated by an assignment just falls through to the plain snackbar below.
      final String? assignmentId = widget.assignedQuestionnaireId;
      if (assignmentId != null && widget.providerEmail != null) {
        final Map<String, String>? interpretation = getInterpretation();
        final String deepLink = QuestionnaireResultPayload.buildDeepLink(
          patientName: widget.patientName ?? 'Your patient',
          templateId: widget.assessmentId,
          score: totalScore,
          summary: interpretation?['summary'] ?? 'Total score: $totalScore',
          action: interpretation?['action'],
        );
        final String body =
            '${widget.assessmentId} completed by ${widget.patientName ?? 'your patient'}.\n\n'
            'Score: $totalScore\n'
            '${interpretation?['summary'] ?? ''}\n'
            '${(interpretation?['action']?.isNotEmpty ?? false) ? 'Recommended action: ${interpretation!['action']}\n' : ''}'
            '\nHave the Progressor app? Tap this link to attach these results to their chart:\n$deepLink';
        final Uri mailUri = Uri(
          scheme: 'mailto',
          path: widget.providerEmail,
          queryParameters: {'subject': '${widget.assessmentId} Results', 'body': body},
        );
        if (await canLaunchUrl(mailUri)) await launchUrl(mailUri);

        await DatabaseManager().markQuestionnaireCompleted(assignmentId);
        await DatabaseManager().appendDiaryEntry(
          widget.patientUuid,
          DateTime.now(),
          'Completed the ${widget.assessmentId} questionnaire — sent to ${widget.providerName ?? 'your care team'}.',
        );

        if (mounted) setState(() => _submitted = true);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assessment saved successfully")));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving assessment: $e")));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Deliberately no score or interpretation shown here — not even once the form is
  // complete. Showing a patient an automated "your PHQ-9 suggests moderate
  // depression" with no clinician in the loop is exactly the false-positive/
  // self-diagnosis risk this whole assigned-questionnaire model exists to avoid (see
  // medical_profile_screen.dart's _checkActiveQuestionnaire doc comment). The real
  // score/interpretation still gets computed — see _submitAssessment — it's just
  // never rendered to the person answering.
  Widget _buildScoreFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey.shade50,
      child: const Text(
        "Your answers go straight to your care team — you won't see a score here.",
        style: TextStyle(fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}
