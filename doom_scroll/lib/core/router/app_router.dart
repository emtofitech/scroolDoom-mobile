import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/landing.dart';
import '../../pages/home.dart';
import '../../pages/app_limits.dart';
import '../../pages/statistics.dart';
import '../../pages/lockout.dart';
import '../../pages/streaks.dart';
import '../../pages/accountability.dart';
import '../../pages/breaches.dart';
import '../../pages/settings.dart';
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
  static const String streaks = '/streaks';
  static const String accountability = '/accountability';
  static const String lockout = '/lockout';
  static const String breaches = '/breaches';
  static const String settings = '/settings';
}

/// Global navigator key — lets services outside the widget tree push routes.
/// Usage: appNavigatorKey.currentContext?.go(AppRoutes.lockout)
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'appNavigator',
);

/// GoRouter configuration for the entire app.
final appRouter = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: AppRoutes.landing,
  routes: [
    GoRoute(
      path: AppRoutes.landing,
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SigninPage(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.limits,
      builder: (context, state) => const AppLimitsPage(),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: AppRoutes.streaks,
      builder: (context, state) => const StreaksPage(),
    ),
    GoRoute(
      path: AppRoutes.accountability,
      builder: (context, state) => const AccountabilityPage(),
    ),
    GoRoute(
      path: AppRoutes.lockout,
      builder: (context, state) {
        final appName = state.uri.queryParameters['app'] ?? 'Instagram';
        return LockoutPage(appName: appName);
      },
    ),
    GoRoute(
      path: AppRoutes.breaches,
      builder: (context, state) => const BreachesPage(),
    ),
  ],
);
