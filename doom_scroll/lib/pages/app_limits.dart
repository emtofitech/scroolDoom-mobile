import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';

const _amber = Color(0xFFFFAA00);

/// Dummy app model for UI only
class AppItem {
  final String name;
  final int limitMinutes;
  final int usageMinutes;

  AppItem({
    required this.name,
    required this.limitMinutes,
    required this.usageMinutes,
  });
}

class AppLimitsPage extends StatefulWidget {
  const AppLimitsPage({super.key});

  @override
  State<AppLimitsPage> createState() => _AppLimitsPageState();
}

class _AppLimitsPageState extends State<AppLimitsPage> {
  final List<AppItem> _apps = [
    AppItem(name: 'Instagram', limitMinutes: 60, usageMinutes: 42),
    AppItem(name: 'TikTok', limitMinutes: 30, usageMinutes: 27),
    AppItem(name: 'YouTube', limitMinutes: 120, usageMinutes: 65),
  ];

  void _showAddAppSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InstalledAppsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _apps.fold(0, (sum, item) => sum + item.limitMinutes);

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    final totalLabel = m == 0 ? '${h}h / day' : '${h}h ${m}m / day';

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 10),

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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              /// HEADING
              const Text(
                'App Limits',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Configure your daily boundaries.\nStay focused and reduce screen time.',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 22),

              /// BANNER
              const _UsagePermissionBanner(),

              const SizedBox(height: 16),

              /// RECLAIM CARD
              _ReclaimCard(onAddApp: _showAddAppSheet),

              const SizedBox(height: 22),

              const Text(
                'TRACKED APPS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              ..._apps.map((app) => _AppLimitCard(app: app)),

              const SizedBox(height: 22),

              _TotalCard(totalLabel: totalLabel),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Usage Permission Banner
/// ─────────────────────────────────────────────────────────

class _UsagePermissionBanner extends StatelessWidget {
  const _UsagePermissionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: _amber, size: 20),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Usage Tracking',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track your screen time and daily app usage.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Enable',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Reclaim Card
/// ─────────────────────────────────────────────────────────

class _ReclaimCard extends StatelessWidget {
  final VoidCallback onAddApp;

  const _ReclaimCard({required this.onAddApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt, color: AppColors.cyan, size: 22),
          ),

          const SizedBox(height: 12),

          const Text(
            'Reclaim Your Focus',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Reduce distractions and stay productive every day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
          ),

          const SizedBox(height: 18),

          GestureDetector(
            onTap: onAddApp,
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'ADD APP',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// App Limit Card
/// ─────────────────────────────────────────────────────────

class _AppLimitCard extends StatelessWidget {
  final AppItem app;

  const _AppLimitCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final progress = app.usageMinutes / app.limitMinutes;

    Color accent = AppColors.cyan;

    if (progress >= 0.9) {
      accent = AppColors.red;
    } else if (progress >= 0.6) {
      accent = _amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.phone_android_outlined, color: accent),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Used ${app.usageMinutes} mins today',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${app.limitMinutes}m',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Slider(
            value: app.limitMinutes.toDouble(),
            min: 5,
            max: 240,
            activeColor: accent,
            inactiveColor: AppColors.outline,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Installed Apps Bottom Sheet
/// ─────────────────────────────────────────────────────────

class _InstalledAppsSheet extends StatelessWidget {
  const _InstalledAppsSheet();

  @override
  Widget build(BuildContext context) {
    final apps = [
      'Facebook',
      'Instagram',
      'TikTok',
      'YouTube',
      'Twitter',
      'Snapchat',
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Select an App',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.apps, color: AppColors.cyan),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          apps[index],
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.cyan,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Total Card
/// ─────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final String totalLabel;

  const _TotalCard({required this.totalLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL SCREEN TIME TARGET',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            totalLabel,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
