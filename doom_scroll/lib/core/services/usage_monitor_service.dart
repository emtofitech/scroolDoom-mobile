import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

// ignore_for_file: unawaited_futures
import '../models/limit_models.dart';
import '../models/usage_models.dart';
import 'breach_service.dart';
import 'usage_service.dart';

/// Singleton that periodically calls POST /api/v1/usage/report and
/// broadcasts any [NewLock] events so the UI can react (e.g. navigate
/// to the lockout screen).
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
      _screenTimeReported.clear();
    }
    debugPrint('🔄 [MONITOR] Updated to ${_trackedAppIds.length} tracked apps');
  }

  /// Stops the periodic timer. Call on logout or when all limits are removed.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _screenTimeReported.clear();
    debugPrint('🔴 [MONITOR] Stopped');
  }

  /// Disposes streams — call only when the app is terminating.
  void dispose() {
    stop();
    _lockController.close();
    _warningController.close();
  }

  // ── Internal tick ─────────────────────────────────────────────────────

  /// Track which apps already had a screen-time breach reported this session
  /// so we don't spam the API on every 60s poll.
  final Set<String> _screenTimeReported = {};

  Future<void> _tick() async {
    if (_trackedAppIds.isEmpty) return;

    debugPrint('⏱ [MONITOR] Tick — reading device usage…');

    // 1. Read current device usage from UsageStatsManager
    final usageMap = await UsageService.getTodayUsage(_trackedAppIds);
    if (usageMap.isEmpty) {
      debugPrint('⏱ [MONITOR] No usage data — skipping report');
      return;
    }

    // 2. Report to backend (non-critical — don't block if it fails)
    final result = await UsageService.reportUsageSnapshot(usageMap);

    if (result.isSuccess) {
      final report = result.data!;

      // 3. Broadcast warnings (approaching limit)
      for (final warning in report.warnings) {
        debugPrint('⚠️ [MONITOR] Warning level ${warning.warningLevel} '
            'for ${warning.appId} (${warning.usageSeconds}s)');
        _warningController.add(warning);
      }

      // 4. Broadcast new locks (limit exceeded) and report screen-time breaches
      for (final lock in report.newLocks) {
        debugPrint('🔒 [MONITOR] New lock for ${lock.appId} '
            'until ${lock.lockedUntil.toLocal()}');
        _lockController.add(lock);

        final limit = _limits[lock.appId];
        if (limit != null) {
          final actualSeconds = usageMap[lock.appId] ?? 0;
          _screenTimeReported.add(lock.appId);
          BreachService.reportScreenTime(
            packageName: lock.appId,
            appLabel: limit.appLabel,
            limitMinutes: limit.dailyLimitMinutes,
            actualMinutes: actualSeconds ~/ 60,
          );
        }
      }
    } else {
      debugPrint('⚠️ [MONITOR] Report failed: ${result.error} — '
          'falling back to client-side detection');
    }

    // 5. Client-side screen-time breach detection (runs regardless of backend)
    //    Catches breaches even when /usage/report returns an error.
    for (final entry in usageMap.entries) {
      final appId = entry.key;
      final actualSeconds = entry.value;
      final limit = _limits[appId];
      if (limit == null) continue;

      final limitSeconds = limit.dailyLimitMinutes * 60;
      if (actualSeconds > limitSeconds && !_screenTimeReported.contains(appId)) {
        _screenTimeReported.add(appId);
        debugPrint('🚫 [MONITOR] Client-side screen-time breach: '
            '$appId (${actualSeconds}s > ${limitSeconds}s)');
        BreachService.reportScreenTime(
          packageName: appId,
          appLabel: limit.appLabel,
          limitMinutes: limit.dailyLimitMinutes,
          actualMinutes: actualSeconds ~/ 60,
        );
      }
    }
  }
}
