import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/landing.dart';
import '../../pages/home.dart';
import '../../pages/app_limits.dart';
import '../../pages/statistics.dart';
import '../../pages/lockout.dart';
import '../../auth_pages/signin.dart';
import '../../auth_pages/signup.dart';

/// Centralized route path constants.
class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String home = '/home';
  static const String limits = '/limits';
  static const String stats = '/stats';
  static const String lockout = '/lockout';
}

/// GoRouter configuration for the entire app.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.landing,
  routes: [
    GoRoute(
      path: AppRoutes.landing,
      name: 'landing',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      name: 'signIn',
      builder: (context, state) => const SigninPage(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      name: 'signUp',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.limits,
      name: 'limits',
      builder: (context, state) => const AppLimitsPage(),
    ),
    GoRoute(
      path: AppRoutes.stats,
      name: 'stats',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: AppRoutes.lockout,
      name: 'lockout',
      builder: (context, state) {
        final appName = state.uri.queryParameters['app'] ?? 'Instagram';
        return LockoutPage(appName: appName);
      },
    ),
  ],
);
