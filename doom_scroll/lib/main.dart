import 'package:doom_scroll/pages/app_limits.dart';
import 'package:doom_scroll/pages/landing.dart';
import 'package:doom_scroll/pages/lockout.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoomScroll',
      home: LockoutPage(appName: ''),
    );
  }
}
