import 'package:carbon_ui/carbon_ui.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarbonStartupScreen(
      background: AppTheme.scaffoldBackgroundColor,
      appName: 'Ally',
      appNameColor: const Color(0xFF00a7be),
      // Nearly closed, solid cyan, a held center — settled, at home. See
      // project_journey_mark_icon memory for the story this maps to.
      mark: const JourneyMark(size: 96, gapWidthDeg: 40, color: Color(0xFF00a7be), centerDot: true),
      initialize: () async {
        // Opens (and, on a fresh install, seeds) the database, then immediately
        // clears that seeded demo content right back out — Ally has no purchase/
        // verification event of its own to hang this on, so "the very first
        // launch" is the event. Only ever happens once; see
        // DatabaseManager.clearDemoDataOnFirstLaunch.
        await DatabaseManager().database;
        await DatabaseManager().clearDemoDataOnFirstLaunch();
      },
      onReady: () async {
        if (context.mounted) Navigator.of(context).pushReplacementNamed('/roster');
      },
    );
  }
}
