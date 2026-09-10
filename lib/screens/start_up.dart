import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the "Triage" slide animation
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 5), // Starts well below the screen
      end: Offset.zero, // Ends at its natural position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    _controller.forward(); // Start the "Triage" slide animation

    await Future.wait([
      // Opens (and, on a fresh install, seeds) the database, then immediately clears
      // that seeded demo content right back out — Ally has no purchase/verification
      // event of its own to hang this on, so "the very first launch" is the event.
      // Only ever happens once; see DatabaseManager.clearDemoDataOnFirstLaunch.
      DatabaseManager().database.then((_) => DatabaseManager().clearDemoDataOnFirstLaunch()),
      Future.delayed(const Duration(seconds: 2)), // Minimum time to show your branding
    ]);

    if (mounted) {
      // Navigate to the actual home screen and remove the splash from history
      Navigator.of(context).pushReplacementNamed('/roster');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor, // Consistent with your clinical aesthetic
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "CWICare",
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            ClipRect(
              // Ensures the text only appears as it slides into the frame
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  "PARTNER",
                  style: TextStyle(
                    color: AppTheme.primaryColor, // Your brand action color
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
