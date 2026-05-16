import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import '../models/api_result.dart';
import '../models/auth_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

/// Service responsible for all authentication operations.
class AuthService {
  AuthService._();

  // ── Register ────────────────────────────────────────────────────────────
  static Future<ApiResult<AuthResponse>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'timezone': DateTime.now().timeZoneName,
        'deviceFingerprint': _generateFingerprint(),
        'fcmToken': 'not-available',
        'platform': _getPlatform(),
      },
    );

    // Network-level error (no HTTP response)
    if (response.isNetworkError) {
      return ApiResult.failure(response.errorMessage ?? 'Network error');
    }

    // Empty body (e.g. CORS block)
    if (response.json == null) {
      return ApiResult.failure(response.errorMessage ?? 'Empty server response');
    }

    final json = response.json!;

    if (response.isSuccess && json['success'] == true && json['data'] != null) {
      return ApiResult.success(AuthResponse.fromJson(json['data']));
    }

    // Error message from API
    final errMsg = json['error']?['message'] ??
        json['message'] ??
        'Registration failed (${response.statusCode})';
    return ApiResult.failure(errMsg);
  }

  // ── Login ───────────────────────────────────────────────────────────────
  /// Calls the login API, persists tokens + user on success.
  static Future<ApiResult<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
        'deviceFingerprint': _generateFingerprint(),
        'fcmToken': 'not-available',
      },
    );

    if (response.isNetworkError) {
      return ApiResult.failure(response.errorMessage ?? 'Network error');
    }

    if (response.json == null) {
      return ApiResult.failure(response.errorMessage ?? 'Empty server response');
    }

    final json = response.json!;

    if (response.isSuccess && json['success'] == true && json['data'] != null) {
      final authData = AuthResponse.fromJson(json['data']);

      // Persist tokens & user info locally
      await TokenStorage.saveTokens(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
      );
      await TokenStorage.saveUser(
        id: authData.user.id,
        username: authData.user.username,
        email: authData.user.email,
      );

      return ApiResult.success(authData);
    }

    final errMsg = json['error']?['message'] ??
        json['message'] ??
        'Login failed (${response.statusCode})';
    return ApiResult.failure(errMsg);
  }

  // ── Refresh Token ──────────────────────────────────────────────────────
  /// Exchanges a refresh token for a new access + refresh token pair.
  static Future<ApiResult<AuthResponse>> refreshToken() async {
    final currentRefresh = await TokenStorage.refreshToken;

    if (currentRefresh == null || currentRefresh.isEmpty) {
      return ApiResult.failure('No refresh token found. Please sign in again.');
    }

    final response = await ApiClient.post(
      ApiEndpoints.refreshToken,
      body: {
        'refreshToken': currentRefresh,
      },
    );

    if (response.isNetworkError) {
      return ApiResult.failure(response.errorMessage ?? 'Network error');
    }

    if (response.json == null) {
      return ApiResult.failure(response.errorMessage ?? 'Empty server response');
    }

    final json = response.json!;

    if (response.isSuccess && json['success'] == true && json['data'] != null) {
      final authData = AuthResponse.fromJson(json['data']);

      // Update stored tokens
      await TokenStorage.saveTokens(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
      );
      await TokenStorage.saveUser(
        id: authData.user.id,
        username: authData.user.username,
        email: authData.user.email,
      );

      return ApiResult.success(authData);
    }

    // Refresh failed — clear stale tokens so the user gets sent to login
    await TokenStorage.clear();

    final errMsg = json['error']?['message'] ??
        json['message'] ??
        'Session expired. Please sign in again.';
    return ApiResult.failure(errMsg);
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  /// Clears local tokens and signs the user out.
  static Future<void> logout() async {
    await TokenStorage.clear();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static String _getPlatform() {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return 'ANDROID';
    }
  }

  static String _generateFingerprint() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'flutter-${_getPlatform().toLowerCase()}-$now';
  }
}
