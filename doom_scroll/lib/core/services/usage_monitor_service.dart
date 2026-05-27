import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../models/usage_models.dart';
import '../services/usage_service.dart';

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
  void start(Set<String> trackedAppIds) {
    if (kIsWeb || trackedAppIds.isEmpty) return;

    _trackedAppIds = trackedAppIds;
    _isRunning = true;

    // Cancel any existing timer before creating a new one
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _tick());

    debugPrint('🟢 [MONITOR] Started — tracking ${_trackedAppIds.length} apps '
        'every ${_interval.inSeconds}s');
  }

  /// Updates the set of tracked apps without restarting the timer.
  void updateTrackedApps(Set<String> trackedAppIds) {
    _trackedAppIds = trackedAppIds;
    debugPrint('🔄 [MONITOR] Updated to ${_trackedAppIds.length} tracked apps');
  }

  /// Stops the periodic timer. Call on logout or when all limits are removed.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('🔴 [MONITOR] Stopped');
  }

  /// Disposes streams — call only when the app is terminating.
  void dispose() {
    stop();
    _lockController.close();
    _warningController.close();
  }

  // ── Internal tick ─────────────────────────────────────────────────────

  Future<void> _tick() async {
    if (_trackedAppIds.isEmpty) return;

    debugPrint('⏱ [MONITOR] Tick — reading device usage…');

    // 1. Read current device usage from UsageStatsManager
    final usageMap = await UsageService.getTodayUsage(_trackedAppIds);
    if (usageMap.isEmpty) {
      debugPrint('⏱ [MONITOR] No usage data — skipping report');
      return;
    }

    // 2. Report to backend — backend evaluates limits and returns warnings/locks
    final result = await UsageService.reportUsageSnapshot(usageMap);

    if (!result.isSuccess) {
      debugPrint('⚠️ [MONITOR] Report failed: ${result.error}');
      return;
    }

    final report = result.data!;

    // 3. Broadcast warnings (approaching limit)
    for (final warning in report.warnings) {
      debugPrint('⚠️ [MONITOR] Warning level ${warning.warningLevel} '
          'for ${warning.appId} (${warning.usageSeconds}s)');
      _warningController.add(warning);
    }

    // 4. Broadcast new locks (limit exceeded)
    for (final lock in report.newLocks) {
      debugPrint('🔒 [MONITOR] New lock for ${lock.appId} '
          'until ${lock.lockedUntil.toLocal()}');
      _lockController.add(lock);
    }
  }
}
