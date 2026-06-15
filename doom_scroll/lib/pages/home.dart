import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';
import '../core/router/app_router.dart';
import '../core/state/auth_controller.dart';
import '../core/services/token_storage.dart';

// Extra colours not in AppColors
const _amber = Color(0xFFFFAA00);
const _green = Color(0xFF00E676);

// ─── Home Page ────────────────────────────────────────────────────────────────
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // ── TOP BAR ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: AppColors.cyan,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "DoomScroll",
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) context.go(AppRoutes.landing);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.red.withOpacity(0.35)),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.red,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.settings),
                        child: Container(
                          padding: const EdgeInsets.all(8),
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── DATE + GREETING ────────────────────────────────────
                  const Text(
                    "OCTOBER 24, 2023",
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<String?>(
                    future: TokenStorage.username,
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? 'User';
                      final welcomeText = ref.watch(authControllerProvider).isGuest
                          ? 'Welcome,\nGuest.'
                          : 'Welcome back,\n$name.';
                      return Text(
                        welcomeText,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ── SCREEN TIME CARD ───────────────────────────────────
                  _ScreenTimeCard(),

                  const SizedBox(height: 14),

                  // ── PRODUCTIVITY SCORE CARD ────────────────────────────
                  _ProductivityCard(),

                  const SizedBox(height: 22),

                  // ── APPS NEARING LIMIT header ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Apps Nearing Limit",
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        child: const Text(
                          "View All",
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── APPS HORIZONTAL SCROLL ─────────────────────────────────
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: const [
                  _AppLimitChip(
                    label: "Instagram",
                    icon: Icons.camera_alt_outlined,
                    timeLeft: "12m",
                    color: _amber,
                    progress: 0.87,
                  ),
                  SizedBox(width: 10),
                  _AppLimitChip(
                    label: "TikTok",
                    icon: Icons.music_note_outlined,
                    timeLeft: "4m",
                    color: AppColors.red,
                    progress: 0.97,
                  ),
                  SizedBox(width: 10),
                  _AppLimitChip(
                    label: "Twitter",
                    icon: Icons.tag_outlined,
                    timeLeft: "28m",
                    color: AppColors.purple,
                    progress: 0.68,
                  ),
                  SizedBox(width: 10),
                  _AppLimitChip(
                    label: "YouTube",
                    icon: Icons.play_circle_outline,
                    timeLeft: "50m",
                    color: AppColors.cyan,
                    progress: 0.58,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── QUOTE CARD ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _QuoteCard(),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ─── Screen Time Card ─────────────────────────────────────────────────────────
class _ScreenTimeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          // Circular arc chart
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _ArcPainter(
                    progress: 1.0,
                    color: AppColors.outline,
                    strokeWidth: 10,
                  ),
                ),
                // Progress arc
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _ArcPainter(
                    progress: 0.58,
                    color: AppColors.cyan,
                    strokeWidth: 10,
                    withGlow: true,
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "2h 45m",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Total Time Spent Today",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _StatPill(
                label: "Daily Goal",
                value: "4h 35m",
                color: AppColors.muted,
              ),
              _StatDivider(),
              _StatPill(
                label: "Remaining",
                value: "1h 50m",
                color: AppColors.cyan,
              ),
              _StatDivider(),
              _StatPill(label: "Saved", value: "42m", color: _green),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({
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
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 28, width: 1, color: AppColors.outline);
  }
}

// ─── Arc Painter ─────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool withGlow;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.withGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Start from bottom-left, sweep clockwise like screenshot
    const startAngle = pi * 0.75; // ~225 degrees
    final sweepAngle = pi * 1.5 * progress; // max 270 degrees

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (withGlow) {
      // Glow layer
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Productivity Card ────────────────────────────────────────────────────────
class _ProductivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: bolt icon + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: AppColors.cyan, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_upward_rounded, color: _green, size: 12),
                    SizedBox(width: 3),
                    Text(
                      "+12% vs Yesterday",
                      style: TextStyle(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            "Productivity\nScore",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 6),

          // Score number
          const Text(
            "84",
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(height: 5, color: AppColors.outline),
                FractionallySizedBox(
                  widthFactor: 0.84,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FF), Color(0xFF7000FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "You're maintaining elite focus today.",
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─── App Limit Chip ───────────────────────────────────────────────────────────
class _AppLimitChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String timeLeft;
  final Color color;
  final double progress;

  const _AppLimitChip({
    required this.label,
    required this.icon,
    required this.timeLeft,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mini arc progress
              SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: AppColors.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: timeLeft,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: " left",
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quote Card ───────────────────────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          // Dots indicator (like a pager)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            '"Your mind deserves a reset."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          Container(width: 32, height: 1, color: AppColors.outline),

          const SizedBox(height: 12),

          const Text(
            "Daily Mindfulness",
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
