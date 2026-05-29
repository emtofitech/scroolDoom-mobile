import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import '../models/api_result.dart';
import '../models/usage_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

/// Reads device-level app usage via Android's UsageStatsManager and
/// exposes all three backend usage endpoints:
///   - POST /api/v1/usage/sync   — daily bulk sync
///   - POST /api/v1/usage/report — real-time tick reporting (returns warnings + locks)
///   - GET  /api/v1/usage/summary — cross-device aggregated summary
class UsageService {
  UsageService._();

  // ── Permission helpers ────────────────────────────────────────────────

  /// Returns true if the app has Android "Usage Access" permission.
  /// Always returns false on web/iOS.
  static Future<bool> hasUsagePermission() async {
    if (kIsWeb) return false;
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(minutes: 1));
      await AppUsage().getAppUsage(start, now);
      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android "Usage Access" settings screen.
  static Future<void> openUsageSettings() async {
    try {
      const channel = MethodChannel('com.doomscroll/usage');
      await channel.invokeMethod('openUsageSettings');
    } catch (_) {
      debugPrint('⚠️ Could not open usage settings automatically.');
    }
  }

  // ── Device usage reading ──────────────────────────────────────────────

  /// Returns `{ packageName → secondsUsedToday }` for [trackedAppIds].
  static Future<Map<String, int>> getTodayUsage(
      Set<String> trackedAppIds) async {
    if (kIsWeb || trackedAppIds.isEmpty) return {};

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final stats = await AppUsage().getAppUsage(startOfDay, now);

      final result = <String, int>{};
      for (final info in stats) {
        if (trackedAppIds.contains(info.packageName)) {
          result[info.packageName] = info.usage.inSeconds;
        }
      }

      debugPrint('📊 [USAGE] Got usage for ${result.length} tracked apps');
      return result;
    } catch (e) {
      debugPrint('⚠️ [USAGE] Failed to get device usage: $e');
      return {};
    }
  }

  // ── POST /api/v1/usage/sync ───────────────────────────────────────────

  /// Bulk-syncs today's cumulative usage for all tracked apps.
  /// Returns the number of entries the backend successfully persisted.
  ///
  /// Call once per session (e.g. on app open / page refresh).
  static Future<ApiResult<UsageSyncResult>> syncUsage(
      Map<String, int> usageData) async {
    if (usageData.isEmpty) {
      return ApiResult.success(const UsageSyncResult(synced: 0));
    }

    try {
      final token = await _requireToken();
      if (token == null) return ApiResult.failure('Not authenticated');

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final payload = usageData.entries
          .map((e) => UsageSyncEntry(
                appId: e.key,
                usageSeconds: e.value,
                date: dateStr,
              ).toJson())
          .toList();

      final response = await ApiClient.post(
        ApiEndpoints.usageSync,
        body: {'usageData': payload},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure('Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        final result = data != null
            ? UsageSyncResult.fromJson(data)
            : const UsageSyncResult(synced: 0);
        debugPrint('✅ [USAGE SYNC] Synced ${result.synced} entries');
        return ApiResult.success(result);
      }

      return ApiResult.failure(
        _errMsg(json, response, 'Sync failed (${response.statusCode})'),
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── POST /api/v1/usage/report ─────────────────────────────────────────

  /// Reports real-time usage ticks to the backend.
  ///
  /// The backend evaluates each tick against daily limits and returns:
  ///   - [UsageReportResult.warnings] — apps approaching their limit
  ///   - [UsageReportResult.newLocks] — apps that just exceeded their limit
  ///
  /// Call this on a periodic timer (e.g. every 60 s) while the user is active.
  static Future<ApiResult<UsageReportResult>> reportTicks(
      List<UsageTick> ticks) async {
    if (ticks.isEmpty) {
      return ApiResult.success(
          const UsageReportResult(processed: 0, warnings: [], newLocks: []));
    }

    try {
      final token = await _requireToken();
      if (token == null) return ApiResult.failure('Not authenticated');

      final response = await ApiClient.post(
        ApiEndpoints.usageReport,
        body: {'ticks': ticks.map((t) => t.toJson()).toList()},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure('Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        final result = data != null
            ? UsageReportResult.fromJson(data)
            : const UsageReportResult(processed: 0, warnings: [], newLocks: []);

        debugPrint(
            '✅ [USAGE REPORT] processed=${result.processed}, '
            'warnings=${result.warnings.length}, newLocks=${result.newLocks.length}');

        return ApiResult.success(result);
      }

      return ApiResult.failure(
        _errMsg(json, response, 'Report failed (${response.statusCode})'),
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  /// Convenience: build ticks from a `{ appId → secondsUsed }` snapshot
  /// and report them all at once with a shared timestamp.
  static Future<ApiResult<UsageReportResult>> reportUsageSnapshot(
      Map<String, int> usageSnapshot) async {
    final ticks = usageSnapshot.entries
        .map((e) => UsageTick.now(e.key, e.value))
        .toList();
    return reportTicks(ticks);
  }

  // ── GET /api/v1/usage/summary ─────────────────────────────────────────

  /// Fetches the cross-device aggregated usage summary from the backend.
  /// Useful for displaying historical totals per app.
  static Future<ApiResult<List<UsageSummaryEntry>>> getSummary() async {
    try {
      final token = await _requireToken();
      if (token == null) return ApiResult.failure('Not authenticated');

      final response = await ApiClient.get(
        ApiEndpoints.usageSummary,
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure('Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final list = (json['data'] as List<dynamic>?)
                ?.map((e) =>
                    UsageSummaryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        debugPrint('✅ [USAGE SUMMARY] ${list.length} entries returned');
        return ApiResult.success(list);
      }

      return ApiResult.failure(
        _errMsg(json, response, 'Summary failed (${response.statusCode})'),
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────

  static String _errMsg(Map<String, dynamic>? json, ApiResponse response, String fallback) {
    final err = json?['error'];
    if (err is Map) {
      return err['message'] ?? fallback;
    } else if (err is String) {
      return err;
    }
    return json?['message'] ?? response.errorMessage ?? fallback;
  }

  static Future<String?> _requireToken() async {
    final t = await TokenStorage.accessToken;
    return (t == null || t.isEmpty) ? null : t;
  }
}
