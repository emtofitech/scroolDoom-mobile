import 'package:doom_scroll/core/state/auth_controller.dart';
import 'package:doom_scroll/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/foreground_monitor_service.dart';
import 'core/services/limits_service.dart';
import 'core/services/token_storage.dart';
import 'core/services/usage_monitor_service.dart';
import 'core/services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      await ref.read(authControllerProvider.notifier).init();
      _autoStartMonitor();
      _syncFcmToken();
    });
  }

  Future<void> _autoStartMonitor() async {
    final result = await LimitsService.getAll();
    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      final packages = result.data!.map((l) => l.packageName).toSet();
      final limitsMap = {for (final l in result.data!) l.packageName: l};
      final token = await TokenStorage.accessToken;
      ForegroundMonitorService.instance.start(packages, authToken: token, limits: limitsMap);
      UsageMonitorService.instance.start(packages, limits: limitsMap);
    }
  }

  Future<void> _syncFcmToken() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    await UserService.updateFcmToken(fcmToken);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DoomScroll',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
