import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ally/classes/acuity.dart';
import 'package:ally/classes/assigned_questionnaire_import.dart';
import 'package:ally/classes/body_zone.dart';
import 'package:ally/classes/care_plan_import.dart';
import 'package:ally/classes/database_manager.dart';
import 'package:ally/screens/assign_questionnaire_screen.dart';
import 'package:ally/screens/home_screen.dart';
import 'package:ally/screens/import_care_plan_screen.dart';
import 'package:ally/screens/panic_alert_screen.dart';
import 'package:ally/screens/start_up.dart';
import 'classes/drugs.dart';
import 'classes/symptom_evaluation.dart';
import 'classes/wearable_data_layer_bridge.dart';
import 'classes/wearable_sync_server.dart';
import 'classes/watch_connectivity_bridge.dart';
import 'package:carbon_ui/colors/carbon_brand.dart';
import 'generated/l10n.dart';
import 'app_theme.dart';

Future<void> main() async {
  // Ensure the binding is ready for the splash screen to render
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Ally's brand color is the real, unmodified Carbon blue — this matches
  // CarbonBrand's own default, but is explicit so it's obvious at a glance
  // rather than relying on "nobody configured it" (see CarbonBrand's doc
  // comment; Acuitage/Progressor configure their own here too).
  CarbonBrand.configure(const Color(0xFF0f62fe));
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

  // ally://import?data=... (a discharge care plan) and
  // ally://assignQuestionnaire?data=... (a clinician-requested mental-wellness
  // questionnaire) — both handed off from a sibling app (Progressor today) with no
  // shared backend. Covers both a cold start (the app wasn't running yet when the
  // link was tapped) and a warm one.
  Future<void> _listenForCarePlanLinks() async {
    final Uri? initial = await _appLinks.getInitialLink();
    if (initial != null) _handleLink(initial);
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'ally') return;
    if (uri.host == 'import') {
      final CarePlanImportPayload? payload = CarePlanImportPayload.tryParse(uri);
      if (payload == null) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => ImportCarePlanScreen(payload: payload)),
      );
    } else if (uri.host == 'assignQuestionnaire') {
      final AssignedQuestionnairePayload? payload = AssignedQuestionnairePayload.tryParse(uri);
      if (payload == null) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => AssignQuestionnaireScreen(payload: payload)),
      );
    }
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
  late final WearableDataLayerBridge _wearableDataLayerBridge = WearableDataLayerBridge(onPanic: _handlePanic);
  late final WatchConnectivityBridge _watchConnectivityBridge = WatchConnectivityBridge(onPanic: _handlePanic);

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
    _wearableDataLayerBridge.stop();
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
    // The two native watch transports come up first and unconditionally. They're the
    // ones a real paired watch uses, they only attach a listener, and neither can
    // fail in a way worth aborting startup over. No-ops on the platform that doesn't
    // have them — the Data Layer bridge on iOS, WatchConnectivity on Android.
    _wearableDataLayerBridge.start();
    _watchConnectivityBridge.start();

    // Always on, not gated behind pairing — this is a same-network prototype server
    // with no auth, so the only real gate is "does anything know the IP to reach it,"
    // which is exactly what pairing communicates out of band (see WearableSyncServer).
    //
    // Binding a socket can fail for reasons that have nothing to do with any watch:
    // a permission the install doesn't hold, or the port already taken. That used to
    // throw straight out of _initializeApp and take the Data Layer bridge down with
    // it, which is how a release build ended up unable to reach the Wear OS watch at
    // all while debug builds were fine. Contained here so the prototype transport can
    // fail on its own without costing the real one.
    try {
      await _wearableSyncServer.start();
    } catch (error) {
      debugPrint('Wearable LAN sync server unavailable, continuing without it: $error');
    }
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
