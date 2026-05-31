import 'package:flutter/foundation.dart' show debugPrint;

import '../models/api_result.dart';
import '../models/auth_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

class UserService {
  UserService._();

  static Future<ApiResult<UserProfile>> getProfile() async {
    try {
      final token = await TokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        return ApiResult.failure('Not authenticated');
      }

      final response = await ApiClient.get(
        ApiEndpoints.usersMe,
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      if (response.isSuccess && response.json != null) {
        final data = response.json!['data'] as Map<String, dynamic>? ?? response.json!;
        return ApiResult.success(UserProfile.fromJson(data));
      }

      return ApiResult.failure(
        response.errorMessage ?? 'Failed to fetch profile (${response.statusCode})',
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  static Future<ApiResult<void>> updateFcmToken(String fcmToken) async {
    try {
      final token = await TokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        return ApiResult.failure('Not authenticated');
      }

      debugPrint('📡 [FCM-SYNC] Updating FCM token on backend');

      final response = await ApiClient.patch(
        ApiEndpoints.usersMeFcm,
        body: {"fcmToken": fcmToken},
        token: token,
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      if (response.isSuccess) {
        debugPrint('📡 [FCM-SYNC] FCM token updated successfully');
        return ApiResult.success(null);
      }

      return ApiResult.failure(
        response.errorMessage ?? 'Failed to update FCM token (${response.statusCode})',
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
