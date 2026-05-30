import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/api_result.dart';
import '../models/auth_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

class AuthService {
  AuthService._();

  static final _firebaseAuth = FirebaseAuth.instance;

  // ───────────────── REGISTER ─────────────────

  static Future<ApiResult<AuthResponse>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Step 1 — Create Firebase account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUid = credential.user!.uid;

      // Step 2 — Get FCM token + Firebase ID token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final idToken = await credential.user!.getIdToken(true);

      // Step 3 — Call backend register
      final response = await ApiClient.post(
        ApiEndpoints.register,
        body: {
          "displayName": username,
          "email": email,
          "firebaseUid": firebaseUid,
          "fcmToken": fcmToken ?? "not-available",
        },
      );

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error');
      }

      if (response.json == null) {
        return ApiResult.failure(
          response.errorMessage ?? 'Empty server response',
        );
      }

      if (response.isSuccess && idToken != null) {
        // Step 4 — Exchange Firebase ID token for backend JWT
        final exchangeResult = await _exchangeToken(idToken);
        if (exchangeResult != null) return exchangeResult;

        return ApiResult.failure('Failed to authenticate session with backend.');
      }

      if (response.isSuccess) {
        final authData = AuthResponse.fromJson(response.json!);
        await _persistAuth(authData);
        return ApiResult.success(authData);
      }

      return ApiResult.failure(
        response.errorMessage ?? 'Registration failed (${response.statusCode})',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(_firebaseErrorMessage(e.code));
    }
  }

  // ───────────────── LOGIN ─────────────────

  static Future<ApiResult<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1 — Sign in with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2 — Get Firebase ID token
      final idToken = await credential.user!.getIdToken(true);
      if (idToken == null) {
        return ApiResult.failure('Failed to get authentication token.');
      }

      // Step 3 — Exchange Firebase ID token for backend JWT
      final exchangeResult = await _exchangeToken(idToken);
      if (exchangeResult != null) return exchangeResult;

      return ApiResult.failure('Failed to authenticate session with backend.');
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(_firebaseErrorMessage(e.code));
    }
  }

  // ───────────────── TOKEN EXCHANGE ─────────────────

  /// Calls /api/v1/auth/firebase-refresh to exchange a Firebase ID token
  /// for a backend-issued JWT. Returns null if the exchange fails.
  static Future<ApiResult<AuthResponse>?> _exchangeToken(String idToken) async {
    debugPrint('🔄 🔄 🔄 [FIREBASE-REFRESH] Sending POST to ${ApiEndpoints.firebaseRefresh}');

    final response = await ApiClient.post(
      ApiEndpoints.firebaseRefresh,
      body: {"refreshToken": idToken},
    );

    debugPrint('🔄 [FIREBASE-REFRESH] status=${response.statusCode}, isSuccess=${response.isSuccess}, isNetworkError=${response.isNetworkError}, json=${response.json}');

    if (response.isNetworkError) {
      debugPrint('🔄 [FIREBASE-REFRESH] FAILED: network error');
      return null;
    }
    if (response.json == null) {
      debugPrint('🔄 [FIREBASE-REFRESH] FAILED: null json');
      return null;
    }
    if (!response.isSuccess) {
      debugPrint('🔄 [FIREBASE-REFRESH] FAILED: non-success status ${response.statusCode}');
      return null;
    }

    final data = response.json!['data'] as Map<String, dynamic>? ?? response.json!;
    debugPrint('🔄 [FIREBASE-REFRESH] extracted data=$data (keys=${data.keys})');

    final backendToken = (data['token'] ?? data['accessToken']) as String?;
    if (backendToken == null || backendToken.isEmpty) {
      debugPrint('🔄 [FIREBASE-REFRESH] FAILED: no token/accessToken in response data');
      return null;
    }

    debugPrint('🔄 [FIREBASE-REFRESH] SUCCESS: got backend token (${backendToken.length} chars)');
    final authData = AuthResponse(
      accessToken: backendToken,
      refreshToken: data['refreshToken'] ?? backendToken,
      expiresIn: 3600,
      user: UserProfile.fromJson(data),
      activeLocks: [],
    );
    await _persistAuth(authData);
    return ApiResult.success(authData);
  }

  // ───────────────── LOGOUT ─────────────────

  static Future<void> logout() async {
    await _firebaseAuth.signOut();
    await TokenStorage.clear();
  }

  // ───────────────── REFRESH ─────────────────

  /// Calls /api/v1/auth/refresh to exchange a refresh token for new access + refresh tokens.
  static Future<ApiResult<AuthResponse>> refreshAccessToken() async {
    try {
      final oldRefreshToken = await TokenStorage.refreshToken;
      if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
        return ApiResult.failure('No refresh token stored.');
      }

      debugPrint('🔄 [TOKEN-REFRESH] Sending POST to ${ApiEndpoints.refreshToken}');

      final response = await ApiClient.post(
        ApiEndpoints.refreshToken,
        body: {"refreshToken": oldRefreshToken},
      );

      debugPrint('🔄 [TOKEN-REFRESH] status=${response.statusCode}, json=${response.json}');

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error during refresh');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure('Empty response during refresh');
      }

      if (response.isSuccess) {
        final authData = AuthResponse.fromJson(json);
        if (authData.accessToken.isNotEmpty) {
          await _persistAuth(authData);
          debugPrint('🔄 [TOKEN-REFRESH] SUCCESS: Saved new tokens.');
          return ApiResult.success(authData);
        }
      }

      if (response.statusCode == 401) {
        debugPrint('🔄 [TOKEN-REFRESH] Refresh token is invalid/expired. Clearing token storage.');
        await TokenStorage.clear();
      }

      return ApiResult.failure(
        response.errorMessage ?? 'Token refresh failed (${response.statusCode})',
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  /// Calls /api/v1/auth/sliding-refresh to re-issue a new access token from a valid refresh token.
  static Future<ApiResult<AuthResponse>> slidingRefresh() async {
    try {
      final oldRefreshToken = await TokenStorage.refreshToken;
      if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
        return ApiResult.failure('No refresh token stored.');
      }

      debugPrint('🔄 [SLIDING-REFRESH] Sending POST to ${ApiEndpoints.slidingRefresh}');

      final response = await ApiClient.post(
        ApiEndpoints.slidingRefresh,
        body: {"refreshToken": oldRefreshToken},
      );

      debugPrint('🔄 [SLIDING-REFRESH] status=${response.statusCode}, json=${response.json}');

      if (response.isNetworkError) {
        return ApiResult.failure(response.errorMessage ?? 'Network error during sliding refresh');
      }

      final json = response.json;
      if (json == null) {
        return ApiResult.failure('Empty response during sliding refresh');
      }

      if (response.isSuccess) {
        final authData = AuthResponse.fromJson(json);
        if (authData.accessToken.isNotEmpty) {
          await _persistAuth(authData);
          debugPrint('🔄 [SLIDING-REFRESH] SUCCESS: Saved new tokens.');
          return ApiResult.success(authData);
        }
      }

      if (response.statusCode == 401) {
        debugPrint('🔄 [SLIDING-REFRESH] Session invalid/expired. Clearing token storage.');
        await TokenStorage.clear();
      }

      return ApiResult.failure(
        response.errorMessage ?? 'Sliding refresh failed (${response.statusCode})',
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ───────────────── HELPERS ─────────────────

  static Future<void> _persistAuth(AuthResponse auth) async {
    if (auth.accessToken.isNotEmpty || auth.refreshToken.isNotEmpty) {
      await TokenStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
    }
    await TokenStorage.saveUser(
      id: auth.user.id,
      username: auth.user.username,
      email: auth.user.email,
    );
  }



  static String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
