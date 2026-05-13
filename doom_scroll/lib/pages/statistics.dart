// statistics_page.dart

import 'package:doom_scroll/pages/lockout.dart';
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';

const _amber = Color(0xFFFFAA00);
const _green = Color(0xFF00E676);

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int selectedTab = 0;

  final tabs = ['Daily', 'Weekly', 'Monthly'];

  final apps = [
    _UsageData(
      name: 'Instagram',
      icon: Icons.camera_alt_outlined,
      used: '2h 14m',
      limit: '45m',
      progress: 0.92,
      color: _amber,
      locked: true,
    ),
    _UsageData(
      name: 'TikTok',
      icon: Icons.music_note_outlined,
      used: '3h 02m',
      limit: '20m',
      progress: 1,
      color: AppColors.red,
      locked: true,
    ),
    _UsageData(
      name: 'Twitter',
      icon: Icons.close,
      used: '42m',
      limit: '90m',
      progress: 0.48,
      color: AppColors.purple,
    ),
    _UsageData(
      name: 'YouTube',
      icon: Icons.play_circle_outline,
      used: '1h 12m',
      limit: '2h',
      progress: 0.61,
      color: AppColors.cyan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(),
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
                    Icons.analytics_outlined,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Statistics',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Behavioral analytics designed to help you\nreclaim focus and reduce compulsive usage.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),

            const SizedBox(height: 24),

            /// HERO CARD
            const _HeroAnalyticsCard(),

            const SizedBox(height: 24),

            /// TABS
            Row(
              children: List.generate(tabs.length, (i) {
                final selected = selectedTab == i;

                return GestureDetector(
                  onTap: () => setState(() => selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [AppColors.cyan, AppColors.purple],
                            )
                          : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : AppColors.outline,
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: selected ? Colors.black : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            const Text(
              'TODAY\'S USAGE',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            ...apps.map((app) {
              if (app.locked) {
                return _LockedCard(app: app);
              }

              return _UsageCard(app: app);
            }),

            const SizedBox(height: 24),

            /// INSIGHTS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.cyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'FOCUS INSIGHTS',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You lose focus most between 11PM–1AM.\n\nTikTok usage spikes after work hours. Consider reducing your limit by 15 minutes.',
                    style: TextStyle(
                      color: AppColors.text,
                      height: 1.6,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _HeroAnalyticsCard extends StatelessWidget {
  const _HeroAnalyticsCard();

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
                        color: AppColors.cyan.withOpacity(0.2),
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
                    value: 0.72,
                    strokeWidth: 10,
                    backgroundColor: AppColors.outline,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                    strokeCap: StrokeCap.round,
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '3h 42m',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Total Usage Today',
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
            children: const [
              _MiniStat(label: 'Reclaimed', value: '1h 20m', color: _green),
              _MiniDivider(),
              _MiniStat(
                label: 'Productivity',
                value: '84%',
                color: AppColors.cyan,
              ),
              _MiniDivider(),
              _MiniStat(label: 'vs Yesterday', value: '-18%', color: _amber),
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

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
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

class _MiniDivider extends StatelessWidget {
  const _MiniDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 28, width: 1, color: AppColors.outline);
  }
}

class _UsageCard extends StatelessWidget {
  final _UsageData app;

  const _UsageCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: app.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(app.icon, color: app.color),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${app.used} used today',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                app.limit,
                style: TextStyle(color: app.color, fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: app.progress,
              minHeight: 7,
              backgroundColor: AppColors.outline,
              valueColor: AlwaysStoppedAnimation(app.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  final _UsageData app;

  const _LockedCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LockoutPage(appName: app.name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.red.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(color: AppColors.red.withOpacity(0.12), blurRadius: 20),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(app.icon, color: AppColors.red),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'LOCKED OUT',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Tap to unlock temporarily',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Icon(Icons.lock_outline, color: AppColors.red),
          ],
        ),
      ),
    );
  }
}

class _UsageData {
  final String name;
  final IconData icon;
  final String used;
  final String limit;
  final double progress;
  final Color color;
  final bool locked;

  _UsageData({
    required this.name,
    required this.icon,
    required this.used,
    required this.limit,
    required this.progress,
    required this.color,
    this.locked = false,
  });
}
