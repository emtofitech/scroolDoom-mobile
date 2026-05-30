import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import '../services/token_storage.dart';

/// Low-level HTTP client.
/// Handles headers, encoding, timeouts, and response logging.
class ApiClient {
  ApiClient._(); // singleton-style usage via static methods

  static const Duration _timeout = Duration(seconds: 90);

  // ── Shared headers ──────────────────────────────────────────────────────
  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Token Refresh Helper ─────────────────────────────────────────────────
  static Future<bool> _refreshTokens() async {
    try {
      final oldRefreshToken = await TokenStorage.refreshToken;
      if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
        debugPrint('⚠️ [APIClient] No refresh token found to perform refresh');
        return false;
      }

      final uri = ApiEndpoints.uri(ApiEndpoints.refreshToken);
      final jsonBody = jsonEncode({"refreshToken": oldRefreshToken});
      
      debugPrint('🔄 [APIClient] Intercepted 401. Requesting token refresh...');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: utf8.encode(jsonBody),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🔄 [APIClient] Refresh response status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
        final accessToken = (data['token'] ?? data['accessToken']) as String?;
        final newRefreshToken = (data['refreshToken'] ?? oldRefreshToken) as String;

        if (accessToken != null && accessToken.isNotEmpty) {
          await TokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: newRefreshToken,
          );
          debugPrint('🔄 [APIClient] Token refresh successful.');
          return true;
        }
      }
      
      if (response.statusCode == 401) {
        debugPrint('🔄 [APIClient] Refresh token is invalid/expired. Clearing token storage.');
        await TokenStorage.clear();
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ [APIClient] Error refreshing token: $e');
      return false;
    }
  }

  // ── POST ────────────────────────────────────────────────────────────────
  static Future<ApiResponse> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = ApiEndpoints.uri(endpoint);
    final jsonBody = jsonEncode(body);

    debugPrint('📡 [POST] $uri');
    debugPrint('📡 [BODY] $jsonBody');

    try {
      var response = await http
          .post(uri, headers: _headers(token: token), body: utf8.encode(jsonBody))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
          'Server is not responding. It may be waking up — please wait a moment and try again.',
        );
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');

      if (response.statusCode == 401 &&
          endpoint != ApiEndpoints.refreshToken &&
          endpoint != ApiEndpoints.slidingRefresh &&
          endpoint != ApiEndpoints.firebaseRefresh) {
        final success = await _refreshTokens();
        if (success) {
          final newToken = await TokenStorage.accessToken;
          debugPrint('🔄 [APIClient] Retrying [POST] $uri with new token');
          response = await http
              .post(uri, headers: _headers(token: newToken), body: utf8.encode(jsonBody))
              .timeout(_timeout, onTimeout: () {
            throw TimeoutException('Request timed out during retry.');
          });
          debugPrint('✅ [Retry][${response.statusCode}] ${response.body}');
        }
      }

      return ApiResponse._fromHttp(response);
    } on TimeoutException catch (e) {
      return ApiResponse.error(e.message ?? 'Request timed out.');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ── GET ─────────────────────────────────────────────────────────────────
  static Future<ApiResponse> get(
    String endpoint, {
    String? token,
  }) async {
    final uri = ApiEndpoints.uri(endpoint);
    debugPrint('📡 [GET] $uri');

    try {
      var response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out.');
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');

      if (response.statusCode == 401 &&
          endpoint != ApiEndpoints.refreshToken &&
          endpoint != ApiEndpoints.slidingRefresh &&
          endpoint != ApiEndpoints.firebaseRefresh) {
        final success = await _refreshTokens();
        if (success) {
          final newToken = await TokenStorage.accessToken;
          debugPrint('🔄 [APIClient] Retrying [GET] $uri with new token');
          response = await http
              .get(uri, headers: _headers(token: newToken))
              .timeout(_timeout, onTimeout: () {
            throw TimeoutException('Request timed out during retry.');
          });
          debugPrint('✅ [Retry][${response.statusCode}] ${response.body}');
        }
      }

      return ApiResponse._fromHttp(response);
    } on TimeoutException catch (e) {
      return ApiResponse.error(e.message ?? 'Request timed out.');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ── PUT ──────────────────────────────────────────────────────────────────
  static Future<ApiResponse> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = ApiEndpoints.uri(endpoint);
    final jsonBody = jsonEncode(body);

    debugPrint('📡 [PUT] $uri');
    debugPrint('📡 [BODY] $jsonBody');

    try {
      var response = await http
          .put(uri, headers: _headers(token: token), body: utf8.encode(jsonBody))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out.');
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');

      if (response.statusCode == 401 &&
          endpoint != ApiEndpoints.refreshToken &&
          endpoint != ApiEndpoints.slidingRefresh &&
          endpoint != ApiEndpoints.firebaseRefresh) {
        final success = await _refreshTokens();
        if (success) {
          final newToken = await TokenStorage.accessToken;
          debugPrint('🔄 [APIClient] Retrying [PUT] $uri with new token');
          response = await http
              .put(uri, headers: _headers(token: newToken), body: utf8.encode(jsonBody))
              .timeout(_timeout, onTimeout: () {
            throw TimeoutException('Request timed out during retry.');
          });
          debugPrint('✅ [Retry][${response.statusCode}] ${response.body}');
        }
      }

      return ApiResponse._fromHttp(response);
    } on TimeoutException catch (e) {
      return ApiResponse.error(e.message ?? 'Request timed out.');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ── DELETE ──────────────────────────────────────────────────────────────
  static Future<ApiResponse> delete(
    String endpoint, {
    String? token,
  }) async {
    final uri = ApiEndpoints.uri(endpoint);
    debugPrint('📡 [DELETE] $uri');

    try {
      var response = await http
          .delete(uri, headers: _headers(token: token))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out.');
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');

      if (response.statusCode == 401 &&
          endpoint != ApiEndpoints.refreshToken &&
          endpoint != ApiEndpoints.slidingRefresh &&
          endpoint != ApiEndpoints.firebaseRefresh) {
        final success = await _refreshTokens();
        if (success) {
          final newToken = await TokenStorage.accessToken;
          debugPrint('🔄 [APIClient] Retrying [DELETE] $uri with new token');
          response = await http
              .delete(uri, headers: _headers(token: newToken))
              .timeout(_timeout, onTimeout: () {
            throw TimeoutException('Request timed out during retry.');
          });
          debugPrint('✅ [Retry][${response.statusCode}] ${response.body}');
        }
      }

      return ApiResponse._fromHttp(response);
    } on TimeoutException catch (e) {
      return ApiResponse.error(e.message ?? 'Request timed out.');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

/// Unified API response — wraps raw HTTP or network errors.
class ApiResponse {
  final int? statusCode;
  final Map<String, dynamic>? json;
  final String? errorMessage;

  bool get isSuccess =>
      statusCode != null &&
      (statusCode == 200 || statusCode == 201 || statusCode == 204);

  bool get isNetworkError => statusCode == null;

  ApiResponse._({this.statusCode, this.json, this.errorMessage});

  factory ApiResponse._fromHttp(http.Response response) {
    if (response.body.isEmpty) {
      return ApiResponse._(
        statusCode: response.statusCode,
        errorMessage: response.statusCode == 204
            ? null
            : (response.statusCode == 403
                ? 'Access denied. Please try signing in again.'
                : 'Server error (${response.statusCode}). Please try again.'),
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse._(statusCode: response.statusCode, json: decoded);
    } on FormatException {
      return ApiResponse._(
        statusCode: response.statusCode,
        errorMessage: 'Bad response from server.',
      );
    }
  }

  factory ApiResponse.error(String message) =>
      ApiResponse._(errorMessage: message);
}
