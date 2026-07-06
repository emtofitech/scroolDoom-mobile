import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

// ignore_for_file: unawaited_futures
import '../models/limit_models.dart';
import '../models/usage_models.dart';
import 'breach_service.dart';
import 'foreground_monitor_service.dart';
import 'limits_service.dart';
import 'lock_service.dart';
import 'notification_service.dart';
import 'usage_service.dart';

/// Singleton that periodically polls device usage and detects screen-time
/// breaches on the client side. Also syncs backend-created locks from
/// POST /api/v1/usage/app-open / app-close analysis.
///
/// Lifecycle:
///   UsageMonitorService.instance.start(trackedAppIds)  — call after auth
///   UsageMonitorService.instance.stop()                — call on logout / dispose
class UsageMonitorService {
  UsageMonitorService._();
  static final UsageMonitorService instance = UsageMonitorService._();

  // ── Config ────────────────────────────────────────────────────────────
  static const Duration _interval = Duration(seconds: 60);

  // ── State ─────────────────────────────────────────────────────────────
  Timer? _timer;
  Set<String> _trackedAppIds = {};
  Map<String, AppLimit> _limits = {};
  bool _isRunning = false;

  /// Usage snapshot taken when monitoring started, used to avoid false
  /// breaches from pre-existing usage (before the limit was set).
  Map<String, int> _initialUsage = {};
  
  /// The most recent usage stats read from the OS.
  Map<String, int> _latestUsage = {};

  /// True on the first tick after start/update — used to record baseline.
  bool _firstTick = true;

  /// Apps that have been unlocked this session. The "baseline exceeds limit"
  /// override is skipped for these so the user doesn't get immediately
  /// re-locked after unlocking an app whose baseline was already over the limit.
  final Set<String> _unlockedDuringSession = {};

  // ── Streams ───────────────────────────────────────────────────────────

  /// Emits every [NewLock] the backend returns.
  /// Listen to this in your widget / navigator to push the lockout screen.
  final StreamController<NewLock> _lockController =
      StreamController<NewLock>.broadcast();
  Stream<NewLock> get onNewLock => _lockController.stream;

  /// Emits every [UsageWarning] (approaching limit).
  final StreamController<UsageWarning> _warningController =
      StreamController<UsageWarning>.broadcast();
  Stream<UsageWarning> get onWarning => _warningController.stream;

  // ── Public API ────────────────────────────────────────────────────────

  bool get isRunning => _isRunning;

  /// Starts the periodic monitor for [trackedAppIds].
  /// Safe to call multiple times — restarts if already running.
  void start(Set<String> trackedAppIds, {Map<String, AppLimit>? limits}) {
    if (kIsWeb || trackedAppIds.isEmpty) return;

    _trackedAppIds = trackedAppIds;
    _limits = limits ?? {};
    _isRunning = true;
    _screenTimeReported.clear();
    _initialUsage.clear();
    _firstTick = true;
    _unlockedDuringSession.clear();

    // Cancel any existing timer before creating a new one
    _timer?.cancel();
    _tick();
    _timer = Timer.periodic(_interval, (_) => _tick());

    debugPrint('🟢 [MONITOR] Started — tracking ${_trackedAppIds.length} apps '
        'every ${_interval.inSeconds}s');
  }

  /// Updates the set of tracked apps without restarting the timer.
  void updateTrackedApps(Set<String> trackedAppIds, {Map<String, AppLimit>? limits}) {
    _trackedAppIds = trackedAppIds;
    if (limits != null) {
      _limits = limits;
      _initialUsage.removeWhere((key, _) => !_trackedAppIds.contains(key));
      _screenTimeReported.removeWhere((key) => !_trackedAppIds.contains(key));
      lockedApps.removeWhere((key) => !_trackedAppIds.contains(key));
      _unlockedDuringSession.removeWhere((key) => !_trackedAppIds.contains(key));
      _firstTick = true;
    }
    debugPrint('🔄 [MONITOR] Updated to ${_trackedAppIds.length} tracked apps');
  }

  /// Removes an app from the locked set (e.g. after unlocking via the lockout page).
  void unlockApp(String packageName) {
    lockedApps.remove(packageName);
    _screenTimeReported.remove(packageName);
    _unlockedDuringSession.add(packageName);
    _nativeUnlockApp(packageName);
    debugPrint('🔓 [MONITOR] Removed lock for $packageName');
  }

  /// Stops the periodic timer. Call on logout or when all limits are removed.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _screenTimeReported.clear();
    lockedApps.clear();
    debugPrint('🔴 [MONITOR] Stopped');
  }

  /// Disposes streams — call only when the app is terminating.
  void dispose() {
    stop();
    _lockController.close();
    _warningController.close();
  }

  // ── Native MethodChannel for app locking ──────────────────────────────
  static const _channel = MethodChannel('com.doomscroll/usage');

  /// Tells the native MonitorService to block this app.
  Future<void> _nativeLockApp(String packageName, String appLabel) async {
    try {
      await _channel.invokeMethod('lockApp', {
        'packageName': packageName,
        'appLabel': appLabel,
      });
      debugPrint('🔒 [MONITOR] Native lockApp called for $packageName');
    } catch (e) {
      debugPrint('⚠️ [MONITOR] Native lockApp failed: $e');
    }
  }

  /// Tells the native MonitorService to unblock this app.
  Future<void> _nativeUnlockApp(String packageName) async {
    try {
      await _channel.invokeMethod('unlockApp', {
        'packageName': packageName,
      });
      debugPrint('🔓 [MONITOR] Native unlockApp called for $packageName');
    } catch (e) {
      debugPrint('⚠️ [MONITOR] Native unlockApp failed: $e');
    }
  }

  // ── Internal tick ─────────────────────────────────────────────────────

  /// Track which apps already had a screen-time breach reported this session
  /// so we don't spam the API on every 60s poll.
  final Set<String> _screenTimeReported = {};

  /// Currently locked apps (package names) — populated from NewLock events.
  final Set<String> lockedApps = {};

  /// Polls GET /api/v1/limits/blocked for backend-created locks
  /// and broadcasts NewLock events for any not yet tracked locally.
  Future<void> _syncBackendLocks() async {
    try {
      final result = await LockService.getBlockedApps();
      if (!result.isSuccess || result.data == null) return;
      for (final blocked in result.data!) {
        final packageName = blocked['packageName'] as String?;
        if (packageName == null || packageName.isEmpty) continue;
        if (lockedApps.contains(packageName)) continue;
        lockedApps.add(packageName);
        final expiresAtStr = blocked['expiresAt'] as String?;
        final lockedUntil = expiresAtStr != null
            ? (DateTime.tryParse(expiresAtStr) ??
                DateTime.now().add(const Duration(hours: 24)))
            : DateTime.now().add(const Duration(hours: 24));
        final appLabel = blocked['appLabel'] as String? ?? packageName;
        _lockController.add(NewLock(
          appId: packageName,
          appLabel: appLabel,
          lockEventId: blocked['id']?.toString() ?? 'backend-$packageName',
          lockedUntil: lockedUntil,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ [MONITOR] Backend lock sync failed: $e');
    }
  }

  Future<void> _tick() async {
    if (_trackedAppIds.isEmpty) return;

    debugPrint('⏱ [MONITOR] Tick — reading device usage…');

    // 1. Read current device usage from UsageStatsManager
    final usageMap = await UsageService.getTodayUsage(_trackedAppIds);
    if (usageMap.isNotEmpty) {
      _latestUsage = Map.from(usageMap);
    } else {
      debugPrint('⏱ [MONITOR] No usage data for tracked apps yet.');
    }

    // 2. Add missing baselines for newly tracked apps
    if (_firstTick) {
      _firstTick = false;
      for (final entry in usageMap.entries) {
        if (!_initialUsage.containsKey(entry.key)) {
          _initialUsage[entry.key] = entry.value;
        }
      }
      debugPrint('⏱ [MONITOR] Baselines updated: $_initialUsage');
    }

    // 3. Sync backend-created locks from app-open/app-close analysis
    await _syncBackendLocks();

    // 4. Client-side screen-time breach detection.
    //    Compares usage SINCE baseline against the limit, so pre-existing
    //    usage before monitoring started never triggers a false alarm.
    for (final entry in usageMap.entries) {
      final appId = entry.key;
      final actualSeconds = entry.value;
      final limit = _limits[appId];
      if (limit == null) continue;

      final limitSeconds = limit.dailyLimitMinutes * 60;
      final baseline = _initialUsage[appId] ?? 0;

      // Only count usage above the baseline. Pre-existing usage
      // before monitoring started never triggers a breach.
      final wasInBaseline = _initialUsage.containsKey(appId);
      int effectiveUsage = wasInBaseline ? actualSeconds - baseline : actualSeconds;
      if (effectiveUsage < 0) effectiveUsage = 0;

      if (effectiveUsage > limitSeconds && !_screenTimeReported.contains(appId)) {
        _screenTimeReported.add(appId);
        lockedApps.add(appId);
        debugPrint('🚫 [MONITOR] Client-side screen-time breach: '
            '$appId (${effectiveUsage}s vs ${limitSeconds}s limit, '
            'baseline=$baseline, total=${actualSeconds}s)');
        BreachService.reportScreenTime(
          packageName: appId,
          appLabel: limit.appLabel,
          limitMinutes: limit.dailyLimitMinutes,
          actualMinutes: actualSeconds ~/ 60,
        );
        BreachService.reportStreakBroken(
          streakName: 'Daily Discipline',
          missedDays: 1,
        );
        NotificationService.showBreachNotification(limit.appLabel);
        // Tell native Android to block this app
        _nativeLockApp(appId, limit.appLabel);
        
        // Call backend auto-lock
        LimitsService.autoLock(packageName: appId).then((res) {
          if (res.isSuccess && res.data != null) {
            debugPrint('🔒 [MONITOR] Backend auto-lock response: ${res.data!['message']}');
          }
        });

        _lockController.add(NewLock(
          appId: appId,
          appLabel: limit.appLabel,
          lockEventId: 'client-$appId',
          lockedUntil: DateTime.now().add(const Duration(hours: 24)),
        ));
      } else {
        debugPrint('⏱ [MONITOR] No breach for $appId: '
            'effective=${effectiveUsage}s, limit=${limitSeconds}s, '
            'baseline=${baseline}s, total=${actualSeconds}s, '
            'alreadyReported=${_screenTimeReported.contains(appId)}');
      }
    }
  }

  /// Evaluates an active session's accumulated foreground time against the limit.
  /// Called periodically by ForegroundMonitorService.
  void checkActiveSession(String appId, int activeSessionSeconds) {
    final limit = _limits[appId];
    if (limit == null) return;

    final limitSeconds = limit.dailyLimitMinutes * 60;
    final baseline = _initialUsage[appId] ?? 0;
    final latestStats = _latestUsage[appId] ?? 0;

    int previousSessionsTime = latestStats - baseline;
    if (previousSessionsTime < 0) previousSessionsTime = 0;

    int effectiveUsage = previousSessionsTime + activeSessionSeconds;

    if (effectiveUsage > limitSeconds && !_screenTimeReported.contains(appId)) {
      _screenTimeReported.add(appId);
      lockedApps.add(appId);
      debugPrint('🚫 [MONITOR] ACTIVE SESSION screen-time breach: '
          '$appId (${effectiveUsage}s vs ${limitSeconds}s limit)');

      BreachService.reportScreenTime(
        packageName: appId,
        appLabel: limit.appLabel,
        limitMinutes: limit.dailyLimitMinutes,
        actualMinutes: effectiveUsage ~/ 60,
      );
      BreachService.reportStreakBroken(
        streakName: 'Daily Discipline',
        missedDays: 1,
      );
      NotificationService.showBreachNotification(limit.appLabel);
      // Tell native Android to block this app
      _nativeLockApp(appId, limit.appLabel);

      // Call backend auto-lock
      LimitsService.autoLock(packageName: appId).then((res) {
        if (res.isSuccess && res.data != null) {
          debugPrint('🔒 [MONITOR] Backend auto-lock response: ${res.data!['message']}');
        }
      });

      _lockController.add(NewLock(
        appId: appId,
        appLabel: limit.appLabel,
        lockEventId: 'client-active-$appId',
        lockedUntil: DateTime.now().add(const Duration(hours: 24)),
      ));
    }
  }
}
