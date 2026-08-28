import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ally/classes/acuity.dart';
import 'package:ally/classes/body_zone.dart';
import 'package:ally/classes/care_plan_import.dart';
import 'package:ally/classes/database_manager.dart';
import 'package:ally/screens/home_screen.dart';
import 'package:ally/screens/import_care_plan_screen.dart';
import 'package:ally/screens/panic_alert_screen.dart';
import 'package:ally/screens/start_up.dart';
import 'classes/drugs.dart';
import 'classes/symptom_evaluation.dart';
import 'classes/wearable_sync_server.dart';
import 'generated/l10n.dart';
import 'app_theme.dart';

Future<void> main() async {
  // Ensure the binding is ready for the splash screen to render
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatefulWidget {
  const LuminescaApp({super.key});

  @override
  State<LuminescaApp> createState() => _LuminescaAppState();
}

class _LuminescaAppState extends State<LuminescaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForCarePlanLinks();
  }

  // ally://import?data=... — a discharge care plan handed off from a sibling app
  // (Progressor today) with no shared backend. Covers both a cold start (the app
  // wasn't running yet when the link was tapped) and a warm one.
  Future<void> _listenForCarePlanLinks() async {
    final Uri? initial = await _appLinks.getInitialLink();
    if (initial != null) _handleLink(initial);
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'ally' || uri.host != 'import') return;
    final CarePlanImportPayload? payload = CarePlanImportPayload.tryParse(uri);
    if (payload == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => ImportCarePlanScreen(payload: payload)),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
  late final WearableSyncServer _wearableSyncServer = WearableSyncServer(onPanic: _handlePanic);

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  // Fires from inside the HTTP server's request handler, not from a widget event —
  // context may already be stale by the time this runs, so mounted is checked same as
  // any other post-async setState/navigation guard.
  void _handlePanic(String patientUuid, String triggerType) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PanicAlertScreen(patientUuid: patientUuid, triggerType: triggerType)),
    );
  }

  @override
  void dispose() {
    _wearableSyncServer.stop();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      DatabaseManager().database,
      AcuityFactory.instance.initialize('assets/assessment/mental_health_acuity.json'),
      TouchImageFactory.instance.initialize('assets/images/touch_points.json'),
      DrugFactory.instance.initialize(),
      SymptomFactory.instance.initialize('assets/assessment/symptoms.json'),
    ]);
    // Always on, not gated behind pairing — this is a same-network prototype server
    // with no auth, so the only real gate is "does anything know the IP to reach it,"
    // which is exactly what pairing communicates out of band (see WearableSyncServer).
    await _wearableSyncServer.start();
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
