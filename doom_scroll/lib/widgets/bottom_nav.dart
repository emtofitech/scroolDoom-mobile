import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/colors.dart';
import '../core/router/app_router.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, this.currentIndex = 0});

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.limits);
        break;
      case 2:
        context.go(AppRoutes.streaks);
        break;
      case 3:
        context.go(AppRoutes.accountability);
        break;
      case 4:
        context.go(AppRoutes.breaches);
        break;
    }
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
        BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_rounded), label: "Streaks"),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Accountability"),
        BottomNavigationBarItem(icon: Icon(Icons.warning_rounded), label: "Breaches"),
      ],
    );
  }
}
