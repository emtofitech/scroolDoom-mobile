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

  String? _authToken;

  void start(Set<String> trackedPackages, {String? authToken}) {
    if (kIsWeb) return;
    _trackedPackages = trackedPackages;
    _authToken = authToken;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _check());
    _startNativeService();
    debugPrint('🟢 [FOREGROUND] Started — monitoring ${trackedPackages.length} apps');
  }

  void updateTrackedApps(Set<String> trackedPackages, {String? authToken}) {
    _trackedPackages = trackedPackages;
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
      debugPrint('⏳ [FOREGROUND] No foreground app detected — retrying next cycle');
      return;
    }

    if (current == _lastForeground) return;

    final wasTracked = _lastForeground != null && _trackedPackages.contains(_lastForeground);
    final isTracked = _trackedPackages.contains(current);

    debugPrint('👁 [FOREGROUND] Switch: $_lastForeground → $current '
        '(wasTracked=$wasTracked, isTracked=$isTracked)');

    if (wasTracked && _lastTrackedOpen != null) {
      final closed = _lastTrackedOpen;
      _lastTrackedOpen = null;
      debugPrint('📤 [FOREGROUND] Tracked app closed: $closed');
      unawaited(AdvancedUsageService.recordAppClose(packageName: closed));
    }

    if (isTracked) {
      _lastTrackedOpen = current;
      debugPrint('📤 [FOREGROUND] Tracked app opened: $current');
      unawaited(AdvancedUsageService.recordAppOpen(packageName: current));
    }

    _lastForeground = current;
  }
}
