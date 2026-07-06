import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/breach_models.dart';
import '../core/state/breach_controller.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';

const _amber = Color(0xFFFFAA00);
const _green = Color(0xFF00E676);

class StreaksPage extends ConsumerStatefulWidget {
  const StreaksPage({super.key});

  @override
  ConsumerState<StreaksPage> createState() => _StreaksPageState();
}

class _StreaksPageState extends ConsumerState<StreaksPage> {
  bool _checkedInToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(breachControllerProvider.notifier).loadBreaches();
    });
  }

  void _handleCheckIn() {
    if (_checkedInToday) return;
    setState(() {
      _checkedInToday = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.black),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Daily reflection logged! Your streak is active. Keep it up! 🔥',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breachState = ref.watch(breachControllerProvider);
    final breaches = breachState.breaches.where((b) => b.breachType == BreachType.screenTimeExceeded).toList();

    // Calculate calendar for current month (30 days approximation)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Group breaches by start of day
    final breachDays = <DateTime>{};
    for (var b in breaches) {
      breachDays.add(DateTime(b.breachedAt.year, b.breachedAt.month, b.breachedAt.day));
    }

    final calendarDays = <bool?>[];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      final currentDay = DateTime(now.year, now.month, i);
      if (currentDay.isAfter(today)) {
        calendarDays.add(null);
      } else {
        if (breachDays.contains(currentDay)) {
          calendarDays.add(false); // breach
        } else {
          calendarDays.add(true); // clean
        }
      }
    }

    // Current streak (count backwards from today until we hit a false)
    int currentStreak = 0;
    for (int i = today.day - 1; i >= 0; i--) {
      if (calendarDays[i] == true) {
        currentStreak++;
      } else {
        break;
      }
    }
    if (_checkedInToday && (calendarDays[today.day - 1] == false || currentStreak == 0)) {
       // if checked in and not breached today
       if (!breachDays.contains(today)) currentStreak++;
    }

    // Longest streak calculation
    int longestStreak = 0;
    int current = 0;
    for (int i = 0; i < calendarDays.length; i++) {
      if (calendarDays[i] == true) {
        current++;
        if (current > longestStreak) longestStreak = current;
      } else if (calendarDays[i] == false) {
        current = 0;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          children: [
            const SizedBox(height: 14),

            /// TOP BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield, color: AppColors.cyan, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'DoomScroll',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.cyan,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Streaks',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your daily discipline is the ultimate prize.\nBuild clean consecutive days and stay focus-driven.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),

            const SizedBox(height: 24),

            /// HERO STREAK PROGRESS CARD
            _StreakHeroCard(
              currentStreak: currentStreak,
              longestStreak: longestStreak,
            ),

            const SizedBox(height: 20),

            /// DAILY REFLECTION CHECK-IN WIDGET
            GestureDetector(
              onTap: _handleCheckIn,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _checkedInToday
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.surface, Color(0xFF1F1235)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _checkedInToday ? AppColors.surface : null,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _checkedInToday
                        ? AppColors.outline
                        : AppColors.purple.withOpacity(0.35),
                  ),
                  boxShadow: _checkedInToday
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.12),
                            blurRadius: 18,
                          )
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _checkedInToday
                            ? _green.withOpacity(0.15)
                            : AppColors.purple.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _checkedInToday
                            ? Icons.check_circle_rounded
                            : Icons.auto_awesome_rounded,
                        color: _checkedInToday ? _green : AppColors.cyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _checkedInToday
                                ? 'Reflection Logged!'
                                : 'Daily Reflection Check-in',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _checkedInToday
                                ? 'Your discipline record is locked in for today.'
                                : 'Tap to reflect on today\'s limits and log clean focus.',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_checkedInToday)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// DISCIPLINE TIER ALERT CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.cyan, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Elite Tier discipline',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You are in the top 5% of disciplined users this week.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'CALENDAR CHECK-IN',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            /// CALENDAR GRID CHECK-IN TRACKER
            _CalendarGrid(days: calendarDays),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const _StreakHeroCard({
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.2),
                        blurRadius: 50,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: (currentStreak / max(longestStreak, 1)).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: AppColors.outline,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentStreak 🔥',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Current Streak',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                label: 'Longest Record',
                value: '$longestStreak Days',
                color: _amber,
                icon: Icons.emoji_events_outlined,
              ),
              Container(height: 28, width: 1, color: AppColors.outline),
              _MiniStat(
                label: 'Win Ratio',
                value: '${((currentStreak / 30) * 100).round()}%',
                color: _green,
                icon: Icons.percent_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<bool?> days;

  const _CalendarGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final state = days[i];
        Color cellBg = AppColors.surface;
        Color borderCol = AppColors.outline;
        Widget? child;

        if (state == true) {
          cellBg = _green.withOpacity(0.12);
          borderCol = _green.withOpacity(0.35);
          child = const Icon(Icons.check, color: _green, size: 16);
        } else if (state == false) {
          cellBg = AppColors.red.withOpacity(0.12);
          borderCol = AppColors.red.withOpacity(0.35);
          child = const Icon(Icons.close, color: AppColors.red, size: 16);
        } else {
          // Null means future
          child = Text(
            '${i + 1}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: cellBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderCol),
          ),
          child: Center(child: child),
        );
      },
    );
  }
}
