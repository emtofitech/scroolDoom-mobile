import '../models/api_result.dart';
import '../models/limit_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

/// Service for all app-limit CRUD operations.
/// Automatically attaches the stored auth token to every request.
class LimitsService {
  LimitsService._();

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

  // ── GET all limits ─────────────────────────────────────────────────────
  static Future<ApiResult<List<AppLimit>>> getAll() async {
    try {
      final token = await _token();
      final response = await ApiClient.get(ApiEndpoints.limits, token: token);

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure(response.errorMessage ?? 'Empty response');
      }

      if (response.isSuccess && json['success'] == true) {
        final list = (json['data'] as List<dynamic>?)
                ?.map((e) => AppLimit.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiResult.success(list);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to load limits'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── POST — create a new limit ──────────────────────────────────────────
  static Future<ApiResult<AppLimit>> create({
    required String packageName,
    required String appLabel,
    required int dailyLimitMinutes,
  }) async {
    try {
      final token = await _token();
      final response = await ApiClient.post(
        ApiEndpoints.limits,
        body: {
          'packageName': packageName,
          'appLabel': appLabel,
          'dailyLimitMinutes': dailyLimitMinutes,
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

      if (response.isSuccess && json['success'] == true && json['data'] != null) {
        return ApiResult.success(
            AppLimit.fromJson(json['data'] as Map<String, dynamic>));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to create limit'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── PUT — update an existing limit ─────────────────────────────────────
  static Future<ApiResult<AppLimit>> update({
    required String id,
    required int dailyLimitMinutes,
  }) async {
    try {
      final token = await _token();
      final response = await ApiClient.put(
        ApiEndpoints.limitById(id),
        body: {
          'dailyLimitMinutes': dailyLimitMinutes,
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

      if (response.isSuccess && json['success'] == true && json['data'] != null) {
        return ApiResult.success(
            AppLimit.fromJson(json['data'] as Map<String, dynamic>));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to update limit'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── DELETE — remove a limit ────────────────────────────────────────────
  static Future<ApiResult<bool>> delete({required String id}) async {
    try {
      final token = await _token();
      final response = await ApiClient.delete(
        ApiEndpoints.limitById(id),
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
        return ApiResult.success(true);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to delete limit'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
