import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

      // Step 2 — Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Step 3 — Call backend
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

      final firebaseUid = credential.user!.uid;

      // Step 2 — Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Step 3 — Call backend
      final response = await ApiClient.post(
        ApiEndpoints.login,
        body: {
          "email": email,
          "firebaseUid": firebaseUid,
          "fcmToken": fcmToken ?? "not-available",
          "deviceFingerprint": _generateFingerprint(),
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

      if (response.isSuccess) {
        final authData = AuthResponse.fromJson(response.json!);
        await _persistAuth(authData);
        return ApiResult.success(authData);
      }

      return ApiResult.failure(
        response.errorMessage ?? 'Login failed (${response.statusCode})',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(_firebaseErrorMessage(e.code));
    }
  }

  // ───────────────── LOGOUT ─────────────────

  static Future<void> logout() async {
    await _firebaseAuth.signOut();
    await TokenStorage.clear();
  }

  // ───────────────── REFRESH ─────────────────
  // (unchanged — keep your existing refreshToken method here)

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

  static String _getPlatform() {
    if (kIsWeb) return "WEB";
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "ANDROID";
      case TargetPlatform.iOS:
        return "IOS";
      default:
        return "UNKNOWN";
    }
  }

  static String _generateFingerprint() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'flutter-${_getPlatform().toLowerCase()}-$now';
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
