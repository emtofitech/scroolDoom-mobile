import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_result.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

class LockService {
  LockService._();

  static Future<String?> _token() async {
    final t = await TokenStorage.accessToken;
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Fetches all currently locked/blocked apps from the backend.
  /// Returns a list of raw JSON maps (packageName, expiresAt, etc).
  static Future<ApiResult<List<Map<String, dynamic>>>> getBlockedApps() async {
    try {
      final token = await _token();
      if (token == null) return ApiResult.failure('Not authenticated');
      debugPrint('📡 [LOCK] Fetching blocked apps…');
      final response = await ApiClient.get(
        ApiEndpoints.limitsBlocked,
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
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        debugPrint('✅ [LOCK] ${list.length} blocked app(s)');
        return ApiResult.success(list);
      }
      return ApiResult.failure('Failed to fetch blocked apps');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<void>> unlockApp(String packageName) async {
    try {
      final token = await _token();
      if (token == null) return ApiResult.failure('Not authenticated');
      debugPrint('📡 [LOCK] Unlocking app: $packageName');
      final response = await ApiClient.delete(
        ApiEndpoints.limitsBlockedByPackage(packageName),
        token: token,
      );
      if (response.isSuccess) {
        debugPrint('✅ [LOCK] App unlocked: $packageName');
        return ApiResult.success(null);
      }
      return ApiResult.failure(response.errorMessage ?? 'Failed to unlock app');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
