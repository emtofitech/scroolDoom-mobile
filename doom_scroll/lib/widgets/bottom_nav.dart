import 'package:doom_scroll/pages/app_limits.dart';
import 'package:doom_scroll/pages/home.dart';
import 'package:doom_scroll/pages/statistics.dart';
import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../pages/lockout.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNav({super.key, this.currentIndex = 0, this.onTap});

  void _handleNavigation(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    Widget page;

    switch (index) {
      case 0:
        page = const HomePage();
        break;

      case 1:
        page = const AppLimitsPage();
        break;

      case 2:
        page = const StatisticsPage();
        break;

      case 3:
        page = const LockoutPage(appName: 'Instagram');
        break;

      default:
        page = const HomePage();
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleNavigation(context, index),
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.cyan,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Limits"),
        BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Stats"),
        BottomNavigationBarItem(icon: Icon(Icons.lock_sharp), label: "Lockout"),
      ],
    );
  }
}
