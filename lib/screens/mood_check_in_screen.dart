import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';
import '../classes/database_manager.dart';
import '../classes/patient_sentiment.dart';

// Shown full-screen two ways: automatically for one of Sentiment's three
// "needsCheckIn" flags (sad/angry/stressed — see patient_sentiment.dart) right after
// tapping it, or on demand for any mood via a long press or double tap on the mood
// widget — someone might want to explain why they're happy just as much as why
// they're stressed. The mood itself is already recorded by the caller before this
// even opens; this screen is only about the optional diary write.
//
// The automatic path starts with a Yes/No prompt (skipPrompt: false) since tapping a
// mood doesn't necessarily mean wanting to write about it. The on-demand path
// (skipPrompt: true) skips straight to the text box — long-pressing/double-tapping
// already is the "yes, I want to write" signal. Answering No, or Nevermind while
// writing, closes with nothing saved. Pressing Done appends whatever was written
// (time-stamped) to today's diary entry. System back mirrors whichever of those is
// the non-saving option for the current stage — never a silent save.
class MoodCheckInScreen extends StatefulWidget {
  final Sentiment mood;
  final String patientUuid;
  final bool skipPrompt;

  const MoodCheckInScreen({super.key, required this.mood, required this.patientUuid, this.skipPrompt = false});

  @override
  State<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends State<MoodCheckInScreen> {
  late bool _writing = widget.skipPrompt;
  bool _showReassurance = false;
  final TextEditingController _controller = TextEditingController();
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Reassurance appears once the patient has actually paused after writing
  // something — not on the first keystroke, and not before there's anything there.
  void _onTextChanged() {
    _pauseTimer?.cancel();
    if (_controller.text.trim().isEmpty) {
      if (_showReassurance) setState(() => _showReassurance = false);
      return;
    }
    _pauseTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_showReassurance) setState(() => _showReassurance = true);
    });
  }

  Future<void> _finish() async {
    final String text = _controller.text.trim();
    if (text.isNotEmpty) {
      await DatabaseManager().appendDiaryEntry(widget.patientUuid, DateTime.now(), text);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // Discards whatever's been typed — distinct from Done, which saves it. A hardware
  // back press while writing reads more like "get me out of here" than "I confirm,"
  // so it mirrors this rather than _finish.
  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_writing) {
          _cancel();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA6C8FF), Color(0xFFD0C3FF), Color(0xFFFFD6E8)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _FrostedCard(child: _writing ? _buildWritingStage() : _buildPromptStage()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptStage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.mood.icon, size: 48, color: widget.mood.color),
        const SizedBox(height: 16),
        Text(
          "It looks like you're feeling ${widget.mood.label.toLowerCase()}.",
          textAlign: TextAlign.center,
          style: CarbonTheme.carbonHeadingTextStyle,
        ),
        const SizedBox(height: 12),
        Text(
          "Do you want to write down what you're feeling or why you feel this way?",
          textAlign: TextAlign.center,
          style: CarbonTheme.carbonTextStyle,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final double half = (constraints.maxWidth - 12) / 2;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarbonCompactButton(
                  label: "No",
                  icon: Symbols.close,
                  width: half,
                  style: CarbonButtonStyle.ghost,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                CarbonCompactButton(
                  label: "Yes",
                  icon: Symbols.edit,
                  width: half,
                  style: CarbonButtonStyle.primary,
                  onTap: () => setState(() => _writing = true),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWritingStage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showReassurance
              ? Text(
                  widget.mood.needsCheckIn
                      ? "I understand why you would feel this way. You can keep this safely "
                            "locked away with me, share it with a care giver later if that feels "
                            "right, or delete it any time you feel like it."
                      : "I understand. You can save this in your diary to remember later, "
                            "or delete it any time you feel like it.",
                  key: const ValueKey('reassurance'),
                  textAlign: TextAlign.center,
                  style: CarbonTheme.carbonTextStyle,
                )
              : Text(
                  "Take your time — write as much or as little as you want.",
                  key: const ValueKey('hint'),
                  textAlign: TextAlign.center,
                  style: CarbonTheme.carbonHintTextStyle,
                ),
        ),
        const SizedBox(height: 16),
        CarbonTextInput(
          label: "What's on your mind",
          controller: _controller,
          maxLines: 6,
          fillColor: Colors.white.withValues(alpha: 0.6),
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double half = (constraints.maxWidth - 12) / 2;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarbonCompactButton(
                  label: "Nevermind",
                  icon: Symbols.close,
                  width: half,
                  style: CarbonButtonStyle.ghost,
                  onTap: _cancel,
                ),
                const SizedBox(width: 12),
                CarbonCompactButton(
                  label: "Done",
                  icon: Symbols.check,
                  width: half,
                  style: CarbonButtonStyle.primary,
                  onTap: _finish,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// The "frosted glass" look — a blurred, translucent panel floating over the
// screen's own color gradient, rather than blurring the whole screen (there's
// nothing behind it to blur).
class _FrostedCard extends StatelessWidget {
  final Widget child;

  const _FrostedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}
