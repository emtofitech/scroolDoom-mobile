import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_result.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

/// Service for advanced usage tracking and notification analytics.
/// Keeps tracking code clean, robust, and isolated from standard background syncs.
class AdvancedUsageService {
  AdvancedUsageService._();

  // ── Helper — get token or fail fast ────────────────────────────────────
  static Future<String> _token() async {
    final t = await TokenStorage.accessToken;
    if (t == null || t.isEmpty) throw Exception('Not authenticated');
    return t;
  }

  /// Parse the standard API error message from a response.
  static String _errMsg(ApiResponse response, String fallback) {
    final err = response.json?['error'];
    if (err is Map) {
      return err['message'] ?? response.errorMessage ?? '$fallback (${response.statusCode})';
    } else if (err is String) {
      return err;
    }
    return response.json?['message'] ??
        response.errorMessage ??
        '$fallback (${response.statusCode})';
  }

  // ── 1. App Open & App Close ─────────────────────────────────────────────

  /// Records when a tracked app opens (comes to foreground).
  /// [packageName] identifies which app was opened (e.g. "com.instagram.android").
  static Future<ApiResult<Map<String, dynamic>>> recordAppOpen({
    String? packageName,
  }) async {
    try {
      final token = await _token();
      final label = packageName ?? 'DoomScroll';
      debugPrint('📡 [ADVANCED USAGE] App open: $label');
      final response = await ApiClient.post(
        ApiEndpoints.usageAppOpen,
        body: packageName != null ? {'packageName': packageName} : {},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] App open recorded: $label');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to record app open'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  /// Records when a tracked app closes (goes to background).
  /// [packageName] identifies which app was closed.
  static Future<ApiResult<Map<String, dynamic>>> recordAppClose({
    String? packageName,
  }) async {
    try {
      final token = await _token();
      final label = packageName ?? 'DoomScroll';
      debugPrint('📡 [ADVANCED USAGE] App close: $label');
      final response = await ApiClient.post(
        ApiEndpoints.usageAppClose,
        body: packageName != null ? {'packageName': packageName} : {},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] App close recorded: $label');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to record app close'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── 2. Keep-Alive Heartbeat ─────────────────────────────────────────────

  /// Sends a heartbeat tick to keep-alive user active session with screen/feature context.
  static Future<ApiResult<Map<String, dynamic>>> sendHeartbeat({
    required String screenName,
    required String featureName,
  }) async {
    try {
      final token = await _token();
      final query = 'screenName=${Uri.encodeComponent(screenName)}&featureName=${Uri.encodeComponent(featureName)}';
      debugPrint('📡 [ADVANCED USAGE] Sending heartbeat ($screenName / $featureName)...');
      
      final response = await ApiClient.post(
        '${ApiEndpoints.usageHeartbeat}?$query',
        body: {},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] Heartbeat synced successfully');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to send heartbeat'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── 3. General Events Tracking ──────────────────────────────────────────

  /// Tracks a specific granular event (such as screen view or interaction duration).
  static Future<ApiResult<Map<String, dynamic>>> trackEvent({
    required String eventType,
    required String screenName,
    required String featureName,
    int durationMs = 0,
    String deviceInfo = 'Android Device',
    String appVersion = '1.0.0',
  }) async {
    try {
      final token = await _token();
      debugPrint('📡 [ADVANCED USAGE] Tracking event $eventType on $screenName...');
      final response = await ApiClient.post(
        ApiEndpoints.usageEvents,
        body: {
          'eventType': eventType,
          'screenName': screenName,
          'featureName': featureName,
          'durationMs': durationMs,
          'deviceInfo': deviceInfo,
          'appVersion': appVersion,
        },
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] Event tracked: $eventType');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to track event'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── 4. Notification Analytics ───────────────────────────────────────────

  /// Tracks when a notification is dispatched or prepared to show.
  static Future<ApiResult<Map<String, dynamic>>> trackNotificationDelivery({
    required String notificationType,
    required String title,
    required String body,
  }) async {
    try {
      final token = await _token();
      debugPrint('📡 [ADVANCED USAGE] Tracking notification delivery...');
      final response = await ApiClient.post(
        ApiEndpoints.usageNotifications,
        body: {
          'notificationType': notificationType,
          'title': title,
          'body': body,
        },
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] Notification delivery tracked');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to track notification delivery'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  /// Marks a specific notification delivery as received on the device.
  static Future<ApiResult<Map<String, dynamic>>> markNotificationDelivered({
    required String deliveryId,
  }) async {
    try {
      final token = await _token();
      debugPrint('📡 [ADVANCED USAGE] Marking notification $deliveryId as delivered...');
      final response = await ApiClient.put(
        ApiEndpoints.usageNotificationDelivered(deliveryId),
        body: {},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] Notification $deliveryId marked as delivered');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to mark notification delivered'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  /// Marks a specific notification delivery as opened/clicked by the user.
  static Future<ApiResult<Map<String, dynamic>>> markNotificationOpened({
    required String deliveryId,
  }) async {
    try {
      final token = await _token();
      debugPrint('📡 [ADVANCED USAGE] Marking notification $deliveryId as opened...');
      final response = await ApiClient.put(
        ApiEndpoints.usageNotificationOpened(deliveryId),
        body: {},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] Notification $deliveryId marked as opened');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to mark notification opened'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── 5. User & Global Analytics ──────────────────────────────────────────

  /// Fetches usage statistics aggregated for the currently signed-in user.
  static Future<ApiResult<Map<String, dynamic>>> getUserStats() async {
    try {
      final token = await _token();
      debugPrint('📡 [ADVANCED USAGE] Fetching user statistics...');
      final response = await ApiClient.get(
        ApiEndpoints.usageStatsMe,
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] User stats loaded: ${data.keys.length} keys');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to fetch user stats'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  /// Fetches global screen time statistics (requires Admin privilege on server).
  static Future<ApiResult<Map<String, dynamic>>> getGlobalStats() async {
    try {
      final token = await _token();
      debugPrint('📡 [ADVANCED USAGE] Fetching global statistics...');
      final response = await ApiClient.get(
        ApiEndpoints.usageStatsGlobal,
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        debugPrint('✅ [ADVANCED USAGE] Global stats loaded: ${data.keys.length} keys');
        return ApiResult.success(data);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to fetch global stats'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
