import '../models/api_result.dart';
import '../models/partner_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

class PartnerService {
  PartnerService._();

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

  static Partnership _parsePartnership(Map<String, dynamic> json) {
    for (final key in ['data', 'partnership', 'invite', 'result']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return Partnership.fromJson(value);
      }
    }
    final direct = Partnership.fromJson(json);
    if (direct.id.isNotEmpty) return direct;
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        final p = Partnership.fromJson(entry.value as Map<String, dynamic>);
        if (p.id.isNotEmpty) return p;
      }
    }
    return direct;
  }

  static Future<ApiResult<Partnership>> generateInvite() async {
    try {
      final token = await _token();
      final response = await ApiClient.post(
        ApiEndpoints.partnershipInvite,
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

      if ((response.isSuccess && json['success'] == true) ||
          response.statusCode == 201) {
        return ApiResult.success(_parsePartnership(json));
      }

      try {
        final partnership = _parsePartnership(json);
        if (partnership.id.isNotEmpty) {
          return ApiResult.success(partnership);
        }
      } catch (_) {}

      return ApiResult.failure(_errMsg(response, 'Failed to generate invite'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<Partnership>> acceptInvite(String inviteCode) async {
    try {
      final token = await _token();
      final response = await ApiClient.post(
        ApiEndpoints.partnershipAccept,
        body: {'inviteCode': inviteCode},
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
        return ApiResult.success(_parsePartnership(json));
      }

      return ApiResult.failure(_errMsg(response, 'Failed to accept invite'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<Partnership>> getMyPartnership() async {
    try {
      final token = await _token();
      final response = await ApiClient.get(
        ApiEndpoints.partnershipMe,
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
        return ApiResult.success(_parsePartnership(json));
      }

      if (response.statusCode == 404) {
        return ApiResult.failure('No active partnership found');
      }

      try {
        final partnership = _parsePartnership(json);
        if (partnership.id.isNotEmpty) {
          return ApiResult.success(partnership);
        }
      } catch (_) {}

      return ApiResult.failure(_errMsg(response, 'Failed to get partnership'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<void>> dissolvePartnership(String id) async {
    try {
      final token = await _token();
      final response = await ApiClient.delete(
        ApiEndpoints.partnershipById(id),
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      if (response.statusCode == 204) {
        return ApiResult.success(null);
      }

      return ApiResult.failure(_errMsg(response, 'Failed to dissolve partnership'));
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
