/// Centralized API endpoint definitions.
/// All backend URLs are defined here — single source of truth.
class ApiEndpoints {
  ApiEndpoints._(); // prevent instantiation

  static const String baseUrl = 'https://scrooldoom-backend.onrender.com';
  static const String _apiVersion = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register = '$_apiVersion/auth/register';
  static const String login = '$_apiVersion/auth/login';
  static const String refreshToken = '$_apiVersion/auth/refresh';
  static const String logout = '$_apiVersion/auth/logout';

  // ── User ──────────────────────────────────────────────────────────────────
  static const String profile = '$_apiVersion/user/profile';
  static const String updateProfile = '$_apiVersion/user/profile';

  // ── App Locks ─────────────────────────────────────────────────────────────
  static const String locks = '$_apiVersion/locks';
  static const String emergencyUnlock = '$_apiVersion/locks/emergency-unlock';

  /// Build a full URL from a relative endpoint path.
  static Uri uri(String endpoint) => Uri.parse('$baseUrl$endpoint');
}
