import 'dart:async';
import 'package:doom_scroll/core/state/auth_controller.dart';
import 'package:doom_scroll/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import 'core/models/limit_models.dart';
import 'core/models/usage_models.dart';
import 'core/router/app_router.dart';
import 'core/services/foreground_monitor_service.dart';
import 'core/services/limits_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/usage_monitor_service.dart';
import 'core/services/token_storage.dart';
import 'core/services/user_service.dart';
import 'core/state/breach_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  StreamSubscription<NewLock>? _lockSub;
  StreamSubscription<UsageWarning>? _warningSub;
  bool _monitorsStarting = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      await ref.read(authControllerProvider.notifier).init();
      // _autoStartMonitor and _syncFcmToken are called by
      // ref.listen in build() — no need to call them here.
      _setupLockListeners();
    });
  }

  void _setupLockListeners() {
    _lockSub?.cancel();
    _lockSub = UsageMonitorService.instance.onNewLock.listen((lock) async {
      if (!mounted) return;
      final appLabel = lock.appLabel.isNotEmpty ? lock.appLabel : lock.appId;

      // Refresh breaches so the UI shows the new breach immediately
      ref.read(breachControllerProvider.notifier).loadBreaches();

      // Show snackbar; grab a fresh context
      var context = appNavigatorKey.currentContext;
      if (context == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$appLabel limit reached — intervention active'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    });

    _warningSub?.cancel();
    _warningSub = UsageMonitorService.instance.onWarning.listen((warning) {
      if (!mounted) return;
      final context = appNavigatorKey.currentContext;
      if (context == null) return;
      final pct = warning.warningLevel;
      if (pct < 1) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${warning.appId}: ${pct}% of limit used'),
          backgroundColor: const Color(0xFFFFAA00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _autoStartMonitor() async {
    if (_monitorsStarting) {
      debugPrint('! [AUTOSTART] Already starting — skipped');
      return;
    }
    _monitorsStarting = true;

    try {
      debugPrint('! [AUTOSTART] Starting monitors...');
      ForegroundMonitorService.instance.stop();
      UsageMonitorService.instance.stop();

      final result = await LimitsService.getAll();
      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        final packages = result.data!.map((l) => l.packageName).toSet();
        final limitsMap = {for (final l in result.data!) l.packageName: l};
        final token = await TokenStorage.accessToken;
        ForegroundMonitorService.instance.start(packages, authToken: token, limits: limitsMap);
        UsageMonitorService.instance.start(packages, limits: limitsMap);
      }
      debugPrint('! [AUTOSTART] Monitors started');
    } finally {
      _monitorsStarting = false;
    }
  }

  Future<void> _syncFcmToken() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    await UserService.updateFcmToken(fcmToken);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _lockSub?.cancel();
    _warningSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start/stop monitors only on actual auth transitions,
    // not when isLoading or error fields toggle.
    ref.listen(authControllerProvider, (previous, next) {
      final wasAuth = previous?.isAuthenticated ?? false;
      final isAuth = next.isAuthenticated;
      if (isAuth == wasAuth) return;

      // Debounce so rapid state flips (init + slidingRefresh + login)
      // collapse into a single monitor start.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (isAuth) {
          _autoStartMonitor();
          _syncFcmToken();
        } else {
          ForegroundMonitorService.instance.stop();
          UsageMonitorService.instance.stop();
        }
      });
    });

    return MaterialApp.router(
      title: 'DoomScroll',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
