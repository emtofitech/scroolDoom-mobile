import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../core/theme/colors.dart';
import '../core/models/limit_models.dart';
import '../core/models/limit_status.dart';
import '../core/services/foreground_monitor_service.dart';
import '../core/services/limits_service.dart';
import '../core/services/usage_monitor_service.dart';
import '../core/services/usage_service.dart';
import '../core/state/auth_controller.dart';
import '../core/router/app_router.dart';
import '../core/services/token_storage.dart';
import '../widgets/bottom_nav.dart';

const _amber = Color(0xFFFFAA00);
const _green = Color(0xFF00E676);

class AppLimitsPage extends ConsumerStatefulWidget {
  const AppLimitsPage({super.key});

  @override
  ConsumerState<AppLimitsPage> createState() => _AppLimitsPageState();
}

class _AppLimitsPageState extends ConsumerState<AppLimitsPage> {
  List<AppLimit> _limits = [];
  Map<String, LimitStatus> _statuses = {};
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshStatuses());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatuses() async {
    final result = await LimitsService.getStatuses();
    if (result.isSuccess && result.data != null && mounted) {
      setState(() {
        _statuses = {for (final s in result.data!) s.packageName: s};
      });
    }
  }

  Future<void> _loadAll() async {
    final isGuest = ref.read(authControllerProvider).isGuest;
    if (isGuest) {
      setState(() {
        _limits = [
          AppLimit(
            id: 'mock-instagram',
            packageName: 'com.instagram.android',
            appLabel: 'Instagram',
            dailyLimitMinutes: 60,
            todayUsageSeconds: 2520, // 42 minutes
          ),
          AppLimit(
            id: 'mock-tiktok',
            packageName: 'com.zhiliaoapp.musically',
            appLabel: 'TikTok',
            dailyLimitMinutes: 30,
            todayUsageSeconds: 1620, // 27 minutes
          ),
          AppLimit(
            id: 'mock-youtube',
            packageName: 'com.google.android.youtube',
            appLabel: 'YouTube',
            dailyLimitMinutes: 120,
            todayUsageSeconds: 3900, // 65 minutes
          ),
        ];
        _isLoading = false;
        _error = null;
      });
      await _updateForegroundMonitor();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await LimitsService.getAll();
    if (!mounted) return;

    if (result.isSuccess) {
      final statusResult = await LimitsService.getStatuses();
      if (statusResult.isSuccess && statusResult.data != null) {
        _statuses = {for (final s in statusResult.data!) s.packageName: s};
      }

      setState(() {
        _limits = result.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _limits = [
          AppLimit(
            id: 'mock-instagram',
            packageName: 'com.instagram.android',
            appLabel: 'Instagram',
            dailyLimitMinutes: 60,
            todayUsageSeconds: 2520,
          ),
          AppLimit(
            id: 'mock-tiktok',
            packageName: 'com.zhiliaoapp.musically',
            appLabel: 'TikTok',
            dailyLimitMinutes: 30,
            todayUsageSeconds: 1620,
          ),
          AppLimit(
            id: 'mock-youtube',
            packageName: 'com.google.android.youtube',
            appLabel: 'YouTube',
            dailyLimitMinutes: 120,
            todayUsageSeconds: 3900,
          ),
        ];
        _isLoading = false;
        _error = null;
      });
    }
    await _updateForegroundMonitor();
  }

  Future<void> _updateForegroundMonitor() async {
    final packages = _limits.map((l) => l.packageName).toSet();
    if (packages.isEmpty) {
      ForegroundMonitorService.instance.stop();
      UsageMonitorService.instance.stop();
      return;
    }

    final limitsMap = {for (final l in _limits) l.packageName: l};
    final token = await TokenStorage.accessToken;
    ForegroundMonitorService.instance.start(packages, authToken: token);
    UsageMonitorService.instance.start(packages, limits: limitsMap);

    if (!await UsageService.hasUsagePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Grant "Usage Access" to detect when tracked apps open'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: Colors.white,
            onPressed: () => UsageService.openUsageSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _createLimit(String packageName, String appLabel, {int dailyLimitMinutes = 30}) async {
    setState(() => _isLoading = true);

    final result = await LimitsService.create(
      packageName: packageName,
      appLabel: appLabel,
      dailyLimitMinutes: dailyLimitMinutes,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      _showSnackBar('$appLabel added with a ${dailyLimitMinutes}m limit');
      _loadAll();
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result.error ?? 'Failed to add app', isError: true);
    }
  }

  Future<void> _updateLimit(AppLimit limit, int newMinutes) async {
    // Optimistic UI update
    setState(() {
      final idx = _limits.indexWhere((l) => l.id == limit.id);
      if (idx != -1) {
        _limits[idx] = AppLimit(
          id: limit.id,
          packageName: limit.packageName,
          appLabel: limit.appLabel,
          dailyLimitMinutes: newMinutes,
          isActive: limit.isActive,
          todayUsageSeconds: limit.todayUsageSeconds,
        );
      }
    });

    final result = await LimitsService.update(
      id: limit.id,
      dailyLimitMinutes: newMinutes,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      _showSnackBar(result.error ?? 'Failed to update limit', isError: true);
      _loadAll(); // Revert on failure
    }
  }

  Future<void> _removeApp(AppLimit limit) async {
    setState(() => _isLoading = true);

    final result = await LimitsService.delete(id: limit.id);
    if (!mounted) return;

    if (result.isSuccess) {
      _showSnackBar('${limit.appLabel} removed');
      _loadAll();
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result.error ?? 'Failed to remove limit', isError: true);
    }
  }

  void _promptGuestToSignIn({required String actionName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  color: AppColors.cyan,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unlock All Features',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To $actionName, please sign in or create a free account. Your settings and screen time history will be securely synced across your devices.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.signIn);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.signUp);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAppSheet() {
    final isGuest = ref.read(authControllerProvider).isGuest;
    if (isGuest) {
      _promptGuestToSignIn(actionName: 'add new app limits');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InstalledAppsSheet(
        trackedPackageNames: _limits.map((l) => l.packageName).toSet(),
        onAppSelected: (String packageName, String appLabel) async {
          Navigator.pop(context);
          final minutes = await _promptLimitMinutes(context, appLabel);
          if (minutes != null && mounted) {
            await _createLimit(packageName, appLabel, dailyLimitMinutes: minutes);
          }
        },
      ),
    );
  }

  Future<int?> _promptLimitMinutes(BuildContext context, String appLabel) {
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        double val = 30;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Limit for $appLabel',
              style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${val.round()} minutes',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: val,
                  min: 1,
                  max: 240,
                  divisions: 239,
                  activeColor: AppColors.cyan,
                  inactiveColor: AppColors.outline,
                  thumbColor: Colors.white,
                  onChanged: (v) => setDialogState(() => val = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, val.round()),
                child: const Text('Add', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _limits.fold<int>(0, (sum, item) => sum + item.dailyLimitMinutes);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final totalLabel = m == 0 ? '${h}h / day' : '${h}h ${m}m / day';

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
            : _error != null
                ? _buildErrorView()
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    color: AppColors.cyan,
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

                          if (_limits.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Center(
                                child: Text(
                                  'No tracked apps yet.\nTap "ADD APP" above to begin.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted, height: 1.5),
                                ),
                              ),
                            )
                          else
                            ..._limits.map((limit) => _AppLimitCard(
                                  limit: limit,
                                  status: _statuses[limit.packageName],
                                  isGuest: ref.read(authControllerProvider).isGuest,
                                  onLimitChanged: (val) => _updateLimit(limit, val),
                                  onRemove: () => _removeApp(limit),
                                  onPromptGuest: () => _promptGuestToSignIn(actionName: 'update daily limits'),
                                )),

                          const SizedBox(height: 22),

                          if (_limits.isNotEmpty) ...[
                            _TotalCard(totalLabel: totalLabel),
                            const SizedBox(height: 28),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _AppLimitCard extends StatefulWidget {
  final AppLimit limit;
  final LimitStatus? status;
  final bool isGuest;
  final Future<void> Function(int) onLimitChanged;
  final VoidCallback onRemove;
  final VoidCallback onPromptGuest;

  const _AppLimitCard({
    required this.limit,
    this.status,
    required this.isGuest,
    required this.onLimitChanged,
    required this.onRemove,
    required this.onPromptGuest,
  });

  @override
  State<_AppLimitCard> createState() => _AppLimitCardState();
}

class _AppLimitCardState extends State<_AppLimitCard> {
  late double _currentSliderVal;
  bool _isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _currentSliderVal = widget.limit.dailyLimitMinutes.toDouble();
  }

  @override
  void didUpdateWidget(covariant _AppLimitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSaving) {
      _currentSliderVal = widget.limit.dailyLimitMinutes.toDouble();
    }
  }

  bool get _isDirty => _currentSliderVal.round() != widget.limit.dailyLimitMinutes;

  Future<void> _handleSave() async {
    if (widget.isGuest) {
      widget.onPromptGuest();
      return;
    }

    setState(() {
      _isSaving = true;
      _hasSaved = false;
    });

    try {
      await widget.onLimitChanged(_currentSliderVal.round());
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasSaved = true;
        });

        // Reset the success state after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasSaved = false;
            });
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.limit.todayUsageSeconds / (widget.limit.dailyLimitMinutes * 60);
    Color accent = AppColors.cyan;

    if (progress >= 0.9) {
      accent = AppColors.red;
    } else if (progress >= 0.6) {
      accent = _amber;
    }

    final usageMinutes = widget.limit.todayUsageSeconds ~/ 60;

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
                      widget.limit.appLabel,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Used $usageMinutes mins today',
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
                  '${_currentSliderVal.round()}m',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.status?.exceeded == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Exceeded',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.isGuest ? widget.onPromptGuest : widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accent,
              inactiveTrackColor: AppColors.outline,
              thumbColor: Colors.white,
              overlayColor: accent.withOpacity(0.15),
            ),
            child: Slider(
              value: _currentSliderVal.clamp(1.0, 240.0),
              min: 1,
              max: 240,
              onChanged: (value) {
                if (widget.isGuest) {
                  widget.onPromptGuest();
                  return;
                }
                setState(() {
                  _currentSliderVal = value;
                  _hasSaved = false;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: (_isSaving || !_isDirty) && !_hasSaved ? null : _handleSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: _hasSaved
                    ? _green.withOpacity(0.12)
                    : (_isSaving
                        ? AppColors.surface
                        : (_isDirty
                            ? AppColors.cyan
                            : AppColors.surface)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasSaved
                      ? _green
                      : (_isSaving
                          ? AppColors.outline
                          : (_isDirty
                              ? AppColors.cyan
                              : AppColors.outline)),
                ),
              ),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyan,
                        ),
                      )
                    : Text(
                        _hasSaved
                            ? 'limit set to ${AppLimit.formatMinutes(_currentSliderVal.round())} daily'
                            : (_isDirty ? 'Set Limit' : 'limit set to ${AppLimit.formatMinutes(widget.limit.dailyLimitMinutes)} daily'),
                        style: TextStyle(
                          color: _hasSaved
                              ? _green
                              : (_isDirty ? Colors.black : AppColors.muted),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstalledAppsSheet extends StatefulWidget {
  final Set<String> trackedPackageNames;
  final Function(String packageName, String appLabel) onAppSelected;

  const _InstalledAppsSheet({
    required this.trackedPackageNames,
    required this.onAppSelected,
  });

  @override
  State<_InstalledAppsSheet> createState() => _InstalledAppsSheetState();
}

class _InstalledAppsSheetState extends State<_InstalledAppsSheet> {
  List<AppInfo> _installedApps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );

      final available = apps
          .where((a) => !widget.trackedPackageNames.contains(a.packageName))
          .toList()
        ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

      if (!mounted) return;
      setState(() {
        _installedApps = available;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                : _installedApps.isEmpty
                    ? const Center(
                        child: Text(
                          'No more apps available to add',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _installedApps.length,
                        itemBuilder: (context, index) {
                          final app = _installedApps[index];
                          final icon = app.icon;

                          return GestureDetector(
                            onTap: () => widget.onAppSelected(app.packageName ?? '', app.name ?? 'Unknown'),
                            child: Container(
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
                                    clipBehavior: Clip.antiAlias,
                                    child: icon != null
                                        ? Image.memory(icon, fit: BoxFit.cover)
                                        : const Icon(Icons.apps, color: AppColors.cyan),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      app.name ?? 'Unknown',
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
