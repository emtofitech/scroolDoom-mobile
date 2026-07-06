import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import '../models/limit_models.dart';
import '../router/app_router.dart';
import 'advanced_usage_service.dart';
import 'breach_service.dart';
import 'usage_monitor_service.dart';

class ForegroundMonitorService {
  ForegroundMonitorService._();
  static final ForegroundMonitorService instance = ForegroundMonitorService._();

  static const String _channel = 'com.doomscroll/usage';
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  Set<String> _trackedPackages = {};
  Map<String, AppLimit> _limits = {};
  String? _lastForeground;
  String? _lastTrackedOpen;
  DateTime? _sessionStart;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  Set<String> get trackedPackages => _trackedPackages;
  String? get currentForegroundApp => _lastForeground;

  String? _authToken;

  /// Tracks which blocked apps (dailyLimitMinutes == 0) were already reported
  /// so we don't spam the API on every 5s poll.
  final Set<String> _blockedReported = {};

  void start(
    Set<String> trackedPackages, {
    String? authToken,
    Map<String, AppLimit>? limits,
  }) {
    if (kIsWeb) return;
    _trackedPackages = trackedPackages;
    _limits = limits ?? {};
    _authToken = authToken;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _check());
    _startNativeService();
    debugPrint(
      '🟢 [FOREGROUND] Started — monitoring ${trackedPackages.length} apps',
    );
  }

  void updateTrackedApps(
    Set<String> trackedPackages, {
    String? authToken,
    Map<String, AppLimit>? limits,
  }) {
    _trackedPackages = trackedPackages;
    if (limits != null) _limits = limits;
    if (authToken != null) _authToken = authToken;
    if (_isRunning) {
      _stopNativeService();
      _startNativeService();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _lastForeground = null;
    _lastTrackedOpen = null;
    _blockedReported.clear();
    _stopNativeService();
    debugPrint('🔴 [FOREGROUND] Stopped');
  }

  Future<void> _startNativeService() async {
    try {
      const channel = MethodChannel(_channel);
      await channel.invokeMethod('startMonitorService', {
        'packages': _trackedPackages.join(','),
        'token': _authToken ?? '',
      });
      debugPrint('🟢 [FOREGROUND] Native service started');
    } catch (e) {
      debugPrint('⚠️ [FOREGROUND] Native service start error: $e');
    }
  }

  Future<void> _stopNativeService() async {
    try {
      const channel = MethodChannel(_channel);
      await channel.invokeMethod('stopMonitorService');
      debugPrint('🔴 [FOREGROUND] Native service stopped');
    } catch (e) {
      debugPrint('⚠️ [FOREGROUND] Native service stop error: $e');
    }
  }

  Future<String?> _getForegroundApp() async {
    try {
      const channel = MethodChannel(_channel);
      final raw = await channel.invokeMethod('getForegroundApp');
      final map = raw as Map?;
      final granted = map?['granted'] == true;
      final app = map?['app'] as String?;
      if (granted == false) {
        debugPrint('🔍 [FOREGROUND] Usage stats permission NOT granted');
      } else {
        debugPrint('🔍 [FOREGROUND] Native returned: $app');
      }
      return app;
    } on MissingPluginException {
      debugPrint('⚠️ [FOREGROUND] MissingPluginException');
      return null;
    } catch (e) {
      debugPrint('⚠️ [FOREGROUND] Error: $e');
      return null;
    }
  }

  Future<void> _check() async {
    if (_trackedPackages.isEmpty) return;

    final current = await _getForegroundApp();
    if (current == null) {
      debugPrint(
        '⏳ [FOREGROUND] No foreground app detected — retrying next cycle',
      );
      return;
    }

    final isTracked = _trackedPackages.contains(current);

    // Always check if the current foreground app is locked, even if the
    // foreground hasn't changed since the last poll (e.g. lock was added
    // by the 60s monitor while user stayed in the same app).
    if (isTracked) {
      if (UsageMonitorService.instance.lockedApps.contains(current)) {
        debugPrint(
          '🔒 [FOREGROUND] Locked app in foreground: $current',
        );
      } else if (current == _lastForeground && _sessionStart != null) {
        final sessionSeconds = DateTime.now().difference(_sessionStart!).inSeconds;
        UsageMonitorService.instance.checkActiveSession(current, sessionSeconds);
      }
    }

    if (current == _lastForeground) return;

    final wasTracked =
        _lastForeground != null && _trackedPackages.contains(_lastForeground);

    debugPrint(
      '👁 [FOREGROUND] Switch: $_lastForeground → $current '
      '(wasTracked=$wasTracked, isTracked=$isTracked)',
    );

    if (wasTracked && _lastTrackedOpen != null) {
      final closed = _lastTrackedOpen;
      _lastTrackedOpen = null;
      debugPrint('📤 [FOREGROUND] Tracked app closed: $closed');
      unawaited(AdvancedUsageService.recordAppClose(packageName: closed));
    }

    if (isTracked) {
      if (_lastTrackedOpen != current) {
        _lastTrackedOpen = current;
        _sessionStart = DateTime.now();
        debugPrint('📤 [FOREGROUND] Tracked app opened: $current');
        unawaited(AdvancedUsageService.recordAppOpen(packageName: current));
      }

      // Report blocked-app breach if dailyLimitMinutes == 0
      final limit = _limits[current];
      if (limit != null &&
          limit.dailyLimitMinutes == 0 &&
          !_blockedReported.contains(current)) {
        _blockedReported.add(current);
        debugPrint('🚫 [FOREGROUND] Blocked app opened: $current');
        unawaited(
          BreachService.reportBlockedApp(
            packageName: current,
            appLabel: limit.appLabel,
          ),
        );
      }

      // If app is currently locked (limit exceeded), navigate to lockout screen
      if (UsageMonitorService.instance.lockedApps.contains(current)) {
        debugPrint(
          '🔒 [FOREGROUND] Locked app opened: $current',
        );
      }
    }

    _lastForeground = current;
  }

}
