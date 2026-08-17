import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/achievement.dart';
import '../classes/achievement_badge.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';

// A horizontal strip of what's been earned so far — hidden entirely until the patient
// has at least one, same "don't clutter the screen with an empty state" rule the
// metrics dashboard's own summary panel already follows.
class TrophyCase extends StatefulWidget {
  final String patientUuid;

  const TrophyCase({super.key, required this.patientUuid});

  @override
  State<TrophyCase> createState() => _TrophyCaseState();
}

class _TrophyCaseState extends State<TrophyCase> {
  late Future<List<Achievement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TrophyCase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientUuid != widget.patientUuid) {
      setState(() => _future = _load());
    }
  }

  Future<List<Achievement>> _load() async {
    final rows = await DatabaseManager().getAchievements(widget.patientUuid);
    // This widget only ever renders once the patient has actually opened the personal
    // details screen and can see it — that's the acknowledgment moment. Fires for every
    // still-unseen trophy at once rather than requiring a tap on each individual one.
    if (await DatabaseManager().hasUnacknowledgedAchievement(
      widget.patientUuid,
    )) {
      await DatabaseManager().acknowledgeAllAchievements(widget.patientUuid);
      await AchievementBadge.instance.refresh();
    }
    return rows.map(Achievement.fromMap).toList();
  }

  void _showDetail(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: carbonColorLayer02,
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.icon ?? "🏆",
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(achievement.name, style: CarbonTheme.carbonHeadingTextStyle),
              if (achievement.reason != null &&
                  achievement.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(achievement.reason!, style: CarbonTheme.carbonTextStyle),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(achievement.earnedAt),
                style: CarbonTheme.carbonHelperTextStyle,
              ),
              const SizedBox(height: 16),
              CarbonCompactButton(
                icon: Symbols.close,
                label: "Close",
                style: CarbonButtonStyle.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => "${d.month}/${d.day}/${d.year}";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Achievement>>(
      future: _future,
      builder: (context, snapshot) {
        final List<Achievement> achievements = snapshot.data ?? const [];
        if (achievements.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Trophy Case", style: CarbonTheme.carbonLabelTextStyle),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: achievements.map((achievement) {
                    return InkWell(
                      onTap: () => _showDetail(achievement),
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: carbonColorBorderSubtle00),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              achievement.icon ?? "🏆",
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              achievement.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CarbonTheme.carbonHelperTextStyle,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
