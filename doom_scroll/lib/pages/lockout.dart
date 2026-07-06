import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/lock_service.dart';
import '../core/services/usage_monitor_service.dart';
import '../core/theme/colors.dart';

class LockoutPage extends StatefulWidget {
  final String appName;
  final String packageName;

  const LockoutPage({
    super.key,
    required this.appName,
    this.packageName = '',
  });

  @override
  State<LockoutPage> createState() => _LockoutPageState();
}

class _LockoutPageState extends State<LockoutPage> {
  int seconds = 900;
  Timer? timer;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds > 0) {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return '$m:$s';
  }

  Future<void> _unlock() async {
    if (_isUnlocking || widget.packageName.isEmpty) return;
    setState(() => _isUnlocking = true);

    final result = await LockService.unlockApp(widget.packageName);
    if (!mounted) return;

    setState(() => _isUnlocking = false);

    if (result.isSuccess) {
      UsageMonitorService.instance.unlockApp(widget.packageName);
      if (context.mounted) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to unlock'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _waitAndDismiss() async {
    Navigator.pop(context);
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Take a deep breath. Stay mindful.'),
          backgroundColor: AppColors.cyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showUnlockSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !_isUnlocking,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Unlock Options',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 16),

              if (_isUnlocking)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppColors.cyan),
                )
              else ...[
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _waitAndDismiss,
                  child: _UnlockOption(
                    title: 'Wait 10 seconds and reflect',
                    subtitle: 'Mindful unlock',
                    color: AppColors.cyan,
                  ),
                ),

                const SizedBox(height: 14),

                GestureDetector(
                  onTap: _unlock,
                  child: _UnlockOption(
                    title: 'Unlock for 5 minutes',
                    subtitle: 'Temporary access',
                    color: const Color(0xFFFFAA00),
                  ),
                ),

                const SizedBox(height: 14),

                GestureDetector(
                  onTap: _unlock,
                  child: _UnlockOption(
                    title: 'Emergency Unlock',
                    subtitle: 'Override intervention',
                    color: AppColors.red,
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031415),

      body: Stack(
        children: [
          /// GLOW
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.2),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),

                          /// TOP BAR
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.shield,
                                    color: AppColors.text,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
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

                              const Icon(
                                Icons.account_circle_outlined,
                                color: AppColors.muted,
                              ),
                            ],
                          ),

                          const Spacer(),

                          const Text(
                            'INTERVENTION ACTIVE',
                            style: TextStyle(
                              color: AppColors.cyan,
                              letterSpacing: 3,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 26),

                          Text(
                            'You\'ve exceeded\nyour ${widget.appName} limit.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'Your mind deserves a reset.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 50),

                          Text(
                            formatted,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 88,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -4,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_dot(active: true), _dot(), _dot()],
                          ),

                          const SizedBox(height: 48),

                          /// BUTTON
                          GestureDetector(
                            onTap: _showUnlockSheet,
                            child: Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.cyan.withOpacity(0.35),
                                ),
                                color: Colors.white.withOpacity(0.02),
                              ),
                              child: const Center(
                                child: Text(
                                  'Unlock options',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// STATS CARD
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time Saved Today',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '2h 45m',
                                      style: TextStyle(
                                        color: AppColors.cyan,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),

                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.transparent,
                                  child: Text(
                                    '82%',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          const Padding(
                            padding: EdgeInsets.only(bottom: 22),
                            child: Text(
                              'Hold to Emergency Unlock',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 28 : 8,
      height: 4,
      decoration: BoxDecoration(
        color: active ? AppColors.text : AppColors.text.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _UnlockOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _UnlockOption({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_open, color: color),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
