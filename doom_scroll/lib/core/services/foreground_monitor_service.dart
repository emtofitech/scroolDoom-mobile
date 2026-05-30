import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'advanced_usage_service.dart';

class ForegroundMonitorService {
  ForegroundMonitorService._();
  static final ForegroundMonitorService instance = ForegroundMonitorService._();

  static const String _channel = 'com.doomscroll/usage';
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  Set<String> _trackedPackages = {};
  String? _lastForeground;
  String? _lastTrackedOpen;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  Set<String> get trackedPackages => _trackedPackages;

  void start(Set<String> trackedPackages) {
    if (kIsWeb) return;
    _trackedPackages = trackedPackages;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _check());
    debugPrint('🟢 [FOREGROUND] Started — monitoring ${trackedPackages.length} apps');
  }

  void updateTrackedApps(Set<String> trackedPackages) {
    _trackedPackages = trackedPackages;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _lastForeground = null;
    _lastTrackedOpen = null;
    debugPrint('🔴 [FOREGROUND] Stopped');
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
      debugPrint('⏳ [FOREGROUND] No foreground app detected — retrying next cycle');
      return;
    }

    if (current == _lastForeground) return;

    final wasTracked = _lastForeground != null && _trackedPackages.contains(_lastForeground);
    final isTracked = _trackedPackages.contains(current);

    debugPrint('👁 [FOREGROUND] Switch: $_lastForeground → $current '
        '(wasTracked=$wasTracked, isTracked=$isTracked)');

    if (isTracked && _lastTrackedOpen != current) {
      debugPrint('📤 [FOREGROUND] Tracked app opened: $current');
      _lastTrackedOpen = current;
      unawaited(AdvancedUsageService.recordAppOpen(packageName: current));
    } else if (wasTracked && !isTracked) {
      final closed = _lastTrackedOpen;
      _lastTrackedOpen = null;
      if (closed != null) {
        debugPrint('📤 [FOREGROUND] Tracked app closed: $closed');
        unawaited(AdvancedUsageService.recordAppClose(packageName: closed));
      }
    }

    _lastForeground = current;
  }
}
