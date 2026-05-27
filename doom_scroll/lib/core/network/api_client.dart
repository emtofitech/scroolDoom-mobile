import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

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
      final response = await http
          .post(uri, headers: _headers(token: token), body: utf8.encode(jsonBody))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
          'Server is not responding. It may be waking up — please wait a moment and try again.',
        );
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');
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
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out.');
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');
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
      final response = await http
          .put(uri, headers: _headers(token: token), body: utf8.encode(jsonBody))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out.');
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');
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
      final response = await http
          .delete(uri, headers: _headers(token: token))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out.');
      });

      debugPrint('✅ [${response.statusCode}] ${response.body}');
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
      statusCode != null && (statusCode == 200 || statusCode == 201);

  bool get isNetworkError => statusCode == null;

  ApiResponse._({this.statusCode, this.json, this.errorMessage});

  factory ApiResponse._fromHttp(http.Response response) {
    if (response.body.isEmpty) {
      return ApiResponse._(
        statusCode: response.statusCode,
        errorMessage:
            'Server returned ${response.statusCode} with no details. '
            'Try testing on a mobile device instead of web.',
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
