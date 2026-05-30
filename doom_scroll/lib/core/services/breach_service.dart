import '../models/api_result.dart';
import '../models/breach_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

class BreachService {
  BreachService._();

  static Future<String> _token() async {
    final t = await TokenStorage.accessToken;
    if (t == null || t.isEmpty) throw Exception('Not authenticated');
    return t;
  }

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

  static Future<ApiResult<Breach>> reportStreakBroken({
    required String streakName,
    required int missedDays,
  }) async {
    try {
      final token = await _token();
      final response = await ApiClient.post(
        ApiEndpoints.breachStreak,
        body: {
          'streakName': streakName,
          'missedDays': missedDays,
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

      if ((response.isSuccess && json['success'] == true) ||
          response.statusCode == 201) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) return ApiResult.success(Breach.fromJson(data));
        return ApiResult.success(Breach.fromJson(json));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to report streak breach'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<Breach>> reportScreenTime({
    required String packageName,
    required String appLabel,
    required int limitMinutes,
    required int actualMinutes,
  }) async {
    try {
      final token = await _token();
      final response = await ApiClient.post(
        ApiEndpoints.breachScreenTime,
        body: {
          'packageName': packageName,
          'appLabel': appLabel,
          'limitMinutes': limitMinutes,
          'actualMinutes': actualMinutes,
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

      if ((response.isSuccess && json['success'] == true) ||
          response.statusCode == 201) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) return ApiResult.success(Breach.fromJson(data));
        return ApiResult.success(Breach.fromJson(json));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to report screen time breach'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<Breach>> reportBlockedApp({
    required String packageName,
    required String appLabel,
  }) async {
    try {
      final token = await _token();
      final response = await ApiClient.post(
        ApiEndpoints.breachBlockedApp,
        body: {
          'packageName': packageName,
          'appLabel': appLabel,
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

      if ((response.isSuccess && json['success'] == true) ||
          response.statusCode == 201) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) return ApiResult.success(Breach.fromJson(data));
        return ApiResult.success(Breach.fromJson(json));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to report blocked app breach'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<Breach>> acknowledgeBreach(String breachId) async {
    try {
      final token = await _token();
      final response = await ApiClient.patch(
        ApiEndpoints.breachAcknowledge(breachId),
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
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) return ApiResult.success(Breach.fromJson(data));
        return ApiResult.success(Breach.fromJson(json));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to acknowledge breach'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<List<Breach>>> getMyBreaches() async {
    try {
      final token = await _token();
      final response = await ApiClient.get(
        ApiEndpoints.breachesMe,
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
        final list = (json['data'] as List<dynamic>?)
                ?.map((e) => Breach.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiResult.success(list);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to load breaches'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<List<Breach>>> getMyBreachesByType(BreachType type) async {
    try {
      final token = await _token();
      final response = await ApiClient.get(
        ApiEndpoints.breachesMeByType(type.apiValue),
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
        final list = (json['data'] as List<dynamic>?)
                ?.map((e) => Breach.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiResult.success(list);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to load breaches by type'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
