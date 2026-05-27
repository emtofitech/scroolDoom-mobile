import 'package:doom_scroll/core/state/auth_controller.dart';
import 'package:doom_scroll/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

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

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    /// 🔥 Initialize auth state ONCE when app starts
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).init();
    });
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
