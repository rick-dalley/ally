import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triage/classes/acuity.dart';
import 'package:triage/classes/body_zone.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/screens/home_screen.dart';
import 'package:triage/screens/start_up.dart';
import 'classes/drugs.dart';
import 'classes/symptom_evaluation.dart';
import 'generated/l10n.dart';
import 'app_theme.dart';

Future<void> main() async {
  // Ensure the binding is ready for the splash screen to render
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatelessWidget {
  const LuminescaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      // Start with your StartupScreen
      home: const StartupScreen(),
      // Define a route for the roster so pushReplacementNamed works
      routes: {'/roster': (context) => const LuminescaHome()},
    );
  }
}

class LuminescaHome extends StatefulWidget {
  const LuminescaHome({super.key});

  @override
  State<StatefulWidget> createState() => LuminescaHomeState();
}

class LuminescaHomeState extends State<LuminescaHome> {
  // We make the initialization a Future that we can listen to
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      DatabaseManager().database,
      AcuityFactory.instance.initialize('assets/assessment/mental_health_acuity.json'),
      TouchImageFactory.instance.initialize('assets/images/touch_points.json'),
      DrugFactory.instance.initialize(),
      SymptomFactory.instance.initialize('assets/assessment/symptoms.json'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      // APPBAR REMOVED ENTIRELY: No global branding banner here anymore.
      body: Stack(
        children: [
          // The Roster: Always present and laid out, containing HomeScreen which handles its own headers
          const HomeScreen(),

          // The Loading Overlay: Only exists while initialization is running
          FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              final isWaiting = snapshot.connectionState == ConnectionState.waiting;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: isWaiting
                    ? Container(
                        key: const ValueKey('loading'),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink(key: ValueKey('loaded')),
              );
            },
          ),
        ],
      ),
    );
  }
}
