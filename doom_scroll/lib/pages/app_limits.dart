import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../core/theme/colors.dart';
import '../core/models/limit_models.dart';
import '../core/models/usage_models.dart';
import '../core/router/app_router.dart';
import '../core/services/limits_service.dart';
import '../core/services/usage_monitor_service.dart';
import '../core/services/usage_service.dart';
import '../widgets/bottom_nav.dart';

const _amber = Color(0xFFFFAA00);
const _green = Color(0xFF00E676);

/// All apps share the same quick-select chip options (in minutes).
const List<int> _chipOptions = [15, 30, 60, 120, 180, 240];

// ── Page ──────────────────────────────────────────────────────────────────────
class AppLimitsPage extends StatefulWidget {
  const AppLimitsPage({super.key});

  @override
  State<AppLimitsPage> createState() => _AppLimitsPageState();
}

class _AppLimitsPageState extends State<AppLimitsPage> {
  List<AppLimit> _limits = [];
  Map<String, int> _deviceUsage = {}; // appId → seconds used today
  bool _isLoading = true;
  bool _hasUsagePermission = false;
  String? _error;

  // Monitor subscriptions
  StreamSubscription<NewLock>? _lockSub;
  StreamSubscription<UsageWarning>? _warningSub;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _subscribeToMonitor();
  }

  void _subscribeToMonitor() {
    final monitor = UsageMonitorService.instance;

    // Navigate to lockout screen when a new lock fires
    _lockSub = monitor.onNewLock.listen((lock) {
      if (!mounted) return;
      final prettyName = _prettyAppName(lock.appId);
      // Navigate using the global navigator key so this works even if
      // the widget is mid-rebuild
      appNavigatorKey.currentContext?.go(
        '${AppRoutes.lockout}?app=$prettyName',
      );
    });

    // Show a snackbar warning when approaching limit
    _warningSub = monitor.onWarning.listen((warning) {
      if (!mounted) return;
      final prettyName = _prettyAppName(warning.appId);
      final usageMins = warning.usageSeconds ~/ 60;
      _showSnackBar(
        '⚠️ $prettyName — ${usageMins}m used today (warning level ${warning.warningLevel})',
        isError: false,
      );
    });
  }

  @override
  void dispose() {
    _lockSub?.cancel();
    _warningSub?.cancel();
    // Don't stop the monitor — it should keep running across page navigation.
    // Call UsageMonitorService.instance.stop() only on logout.
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Check usage permission
    _hasUsagePermission = await UsageService.hasUsagePermission();

    // Fetch limits from API
    final result = await LimitsService.getAll();

    if (!mounted) return;

    if (result.isSuccess) {
      _limits = result.data!;

      // If we have permission, fetch device usage for tracked apps
      if (_hasUsagePermission && _limits.isNotEmpty) {
        final trackedIds = _limits.map((l) => l.appId).toSet();
        _deviceUsage = await UsageService.getTodayUsage(trackedIds);

        // Sync cumulative usage to backend (fire and forget)
        if (_deviceUsage.isNotEmpty) {
          UsageService.syncUsage(_deviceUsage);
        }

        // Start / update the background monitor
        if (trackedIds.isNotEmpty) {
          final monitor = UsageMonitorService.instance;
          if (monitor.isRunning) {
            monitor.updateTrackedApps(trackedIds);
          } else {
            monitor.start(trackedIds);
          }
        }
      }
    } else {
      _error = result.error;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _removeApp(AppLimit limit) async {
    final result = await LimitsService.delete(id: limit.id);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _limits.removeWhere((l) => l.appId == limit.appId);
        _deviceUsage.remove(limit.appId);
      });
      _showSnackBar('${_prettyAppName(limit.appId)} removed');
    } else {
      _showSnackBar(result.error ?? 'Delete failed', isError: true);
    }
  }

  Future<void> _updateLimit(AppLimit limit, int newLimitSeconds) async {
    final result = await LimitsService.update(
      id: limit.id,
      dailyLimitSeconds: newLimitSeconds,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        final idx = _limits.indexWhere((l) => l.appId == limit.appId);
        if (idx != -1) _limits[idx] = result.data!;
      });
    } else {
      _showSnackBar(result.error ?? 'Update failed', isError: true);
    }
  }

  void _showAddAppSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InstalledAppsSheet(
        trackedAppIds: _limits.map((l) => l.appId).toSet(),
        onAppSelected: (String appId) async {
          Navigator.pop(context);
          await _createLimit(appId);
        },
      ),
    );
  }

  Future<void> _createLimit(String appId) async {
    // Default to 1 hour (3600 seconds)
    final result = await LimitsService.create(
      appId: appId,
      dailyLimitSeconds: 3600,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _limits.add(result.data!));
      _showSnackBar('${_prettyAppName(appId)} added', isError: false);
    } else {
      _showSnackBar(result.error ?? 'Failed to add app', isError: true);
    }
  }

  Future<void> _requestUsagePermission() async {
    await UsageService.openUsageSettings();
    // Re-check after user returns from settings
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _loadAll();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF3B5C) : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _prettyAppName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length >= 2) {
      final name = parts[parts.length - 2];
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return packageName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              )
            : _error != null
            ? _ErrorView(message: _error!, onRetry: _loadAll)
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final totalMinutes = _limits.fold<int>(0, (sum, l) => sum + l.limitMinutes);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final totalLabel = m == 0 ? '${h}h / day' : '${h}h ${m}m / day';

    return RefreshIndicator(
      color: AppColors.cyan,
      backgroundColor: AppColors.surface,
      onRefresh: _loadAll,
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
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure your daily boundaries. Once reached,\nDoomScroll will intervene with a mindful lockout.',
              style: TextStyle(
                color: AppColors.muted,
                height: 1.5,
                fontSize: 13.5,
              ),
            ),

            const SizedBox(height: 22),

            /// USAGE PERMISSION BANNER
            if (!_hasUsagePermission)
              _UsagePermissionBanner(onEnable: _requestUsagePermission),

            if (!_hasUsagePermission) const SizedBox(height: 16),

            /// RECLAIM FOCUS CARD
            _ReclaimCard(onAddApp: _showAddAppSheet),

            const SizedBox(height: 22),

            /// SECTION LABEL
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
                    'No apps tracked yet.\nTap "ADD APP" above to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                ),
              ),

            /// APP LIMIT CARDS
            ...List.generate(_limits.length, (i) {
              final limit = _limits[i];
              // Prefer device usage if available, else fallback to API value
              final usageSeconds =
                  _deviceUsage[limit.appId] ?? limit.todayUsageSeconds;
              return _AppLimitCard(
                key: ValueKey(limit.appId),
                limit: limit,
                deviceUsageSeconds: usageSeconds,
                onLimitChanged: (seconds) => _updateLimit(limit, seconds),
                onRemove: () => _removeApp(limit),
              );
            }),

            const SizedBox(height: 22),

            if (_limits.isNotEmpty) ...[
              /// TOTAL SCREEN TIME TARGET
              _TotalCard(totalLabel: totalLabel),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Usage Permission Banner ──────────────────────────────────────────────────
class _UsagePermissionBanner extends StatelessWidget {
  final VoidCallback onEnable;
  const _UsagePermissionBanner({required this.onEnable});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
                  'Grant Usage Access so DoomScroll can monitor your screen time.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEnable,
            child: Container(
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
          ),
        ],
      ),
    );
  }
}

// ── Installed Apps Bottom Sheet ───────────────────────────────────────────────
class _InstalledAppsSheet extends StatefulWidget {
  final Set<String> trackedAppIds;
  final ValueChanged<String> onAppSelected;

  const _InstalledAppsSheet({
    required this.trackedAppIds,
    required this.onAppSelected,
  });

  @override
  State<_InstalledAppsSheet> createState() => _InstalledAppsSheetState();
}

class _InstalledAppsSheetState extends State<_InstalledAppsSheet> {
  List<AppInfo> _allApps = [];
  List<AppInfo> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    try {
      // Get only non-system (user-installed) apps, with icons
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      // Filter out already-tracked apps
      final available =
          apps
              .where((a) => !widget.trackedAppIds.contains(a.packageName))
              .toList()
            ..sort(
              (a, b) => (a.name ?? '').toLowerCase().compareTo(
                (b.name ?? '').toLowerCase(),
              ),
            );

      if (!mounted) return;
      setState(() {
        _allApps = available;
        _filtered = available;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _allApps
          .where(
            (a) =>
                (a.name ?? '').toLowerCase().contains(q) ||
                (a.packageName ?? '').toLowerCase().contains(q),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          /// Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 16),

          /// Title
          const Text(
            'Select an App',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          /// Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.cyan,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// App list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                : _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No apps found',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final app = _filtered[i];
                      return _AppTile(
                        app: app,
                        onTap: () =>
                            widget.onAppSelected(app.packageName ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Single app tile in the picker ─────────────────────────────────────────────
class _AppTile extends StatefulWidget {
  final AppInfo app;
  final VoidCallback onTap;
  const _AppTile({required this.app, required this.onTap});

  @override
  State<_AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<_AppTile> {
  Uint8List? get _icon => widget.app.icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            /// App icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              clipBehavior: Clip.antiAlias,
              child: _icon != null
                  ? Image.memory(_icon!, fit: BoxFit.cover)
                  : const Icon(Icons.android, color: AppColors.muted, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.app.name ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.app.packageName ?? '',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.cyan,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reclaim Focus Card ────────────────────────────────────────────────────────
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
            'The average user saves 4.2 hours per week by implementing these tactical boundaries. Your mental clarity is the ultimate prize.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 18),

          /// ADD APP button
          GestureDetector(
            onTap: onAddApp,
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
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

// ── App Limit Card ────────────────────────────────────────────────────────────
class _AppLimitCard extends StatelessWidget {
  final AppLimit limit;
  final int deviceUsageSeconds;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback onRemove;

  const _AppLimitCard({
    super.key,
    required this.limit,
    required this.deviceUsageSeconds,
    required this.onLimitChanged,
    required this.onRemove,
  });

  /// Progress based on device usage vs limit.
  double get _progress => limit.dailyLimitSeconds > 0
      ? deviceUsageSeconds / limit.dailyLimitSeconds
      : 0;

  /// Determine accent colour based on usage progress.
  Color get _accentColor {
    if (_progress >= 0.9) return AppColors.red;
    if (_progress >= 0.6) return _amber;
    return AppColors.cyan;
  }

  /// Status label based on progress.
  String get _status {
    if (_progress >= 0.9) return 'Critical';
    if (_progress >= 0.6) return 'High Risk';
    return 'Moderate';
  }

  @override
  Widget build(BuildContext context) {
    final limitMins = limit.limitMinutes;
    final usageMins = deviceUsageSeconds ~/ 60;
    final accent = _accentColor;
    const maxSlider = 240.0; // 4 hours max

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
          /// Header row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.phone_android_outlined,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _prettyAppName(limit.appId),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Used: ${AppLimit.formatMinutes(usageMins)} today',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              /// Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// Remove button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.red,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Daily limit label + current value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY LIMIT',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                AppLimit.formatMinutes(limitMins),
                style: TextStyle(
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          /// Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: accent,
              inactiveTrackColor: AppColors.outline,
              thumbColor: Colors.white,
              overlayColor: accent.withOpacity(0.15),
            ),
            child: Slider(
              min: 5,
              max: maxSlider,
              value: limitMins.toDouble().clamp(5.0, maxSlider),
              onChanged: (v) =>
                  onLimitChanged(v.round() * 60), // convert to seconds
            ),
          ),

          const SizedBox(height: 6),

          /// Quick-select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _chipOptions.map((m) {
              final selected = limitMins == m;
              return GestureDetector(
                onTap: () => onLimitChanged(m * 60), // convert to seconds
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? accent : accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? accent : accent.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    AppLimit.formatMinutes(m),
                    style: TextStyle(
                      color: selected ? Colors.black : accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Extracts a readable name from a package name.
  /// e.g. "com.instagram.android" → "Instagram"
  String _prettyAppName(String packageName) {
    final parts = packageName.split('.');
    // Try the second-to-last part, capitalize it
    if (parts.length >= 2) {
      final name = parts[parts.length - 2];
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return packageName;
  }
}

// ── Total Card ────────────────────────────────────────────────────────────────
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'TOTAL SCREEN TIME TARGET',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.edit_outlined, color: AppColors.muted, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalLabel,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
