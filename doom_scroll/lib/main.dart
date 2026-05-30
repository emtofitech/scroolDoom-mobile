import 'package:doom_scroll/core/state/auth_controller.dart';
import 'package:doom_scroll/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/foreground_monitor_service.dart';
import 'core/services/limits_service.dart';

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
    });
  }

  Future<void> _autoStartMonitor() async {
    final result = await LimitsService.getAll();
    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      final packages = result.data!.map((l) => l.packageName).toSet();
      ForegroundMonitorService.instance.start(packages);
    }
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
