/// Centralized API endpoint definitions.
/// All backend URLs are defined here — single source of truth.
class ApiEndpoints {
  ApiEndpoints._(); // prevent instantiation

  static const String baseUrl = 'https://doomscroll-aotr.onrender.com';
  static const String _apiVersion = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register = '$_apiVersion/auth/register';
  static const String login = '$_apiVersion/auth/login';
  static const String firebaseRefresh = '$_apiVersion/auth/firebase-refresh';
  static const String refreshToken = '$_apiVersion/auth/refresh';
  static const String slidingRefresh = '$_apiVersion/auth/sliding-refresh';
  static const String logout = '$_apiVersion/auth/logout';

  // ── User ──────────────────────────────────────────────────────────────────
  static const String profile = '$_apiVersion/user/profile';
  static const String updateProfile = '$_apiVersion/user/profile';

  // ── App Limits ────────────────────────────────────────────────────────────
  static const String limits = '$_apiVersion/limits';
  static String limitById(String id) => '$_apiVersion/limits/$id';
  static const String limitsStatus = '$_apiVersion/limits/status';

  // ── App Locks ─────────────────────────────────────────────────────────────
  static const String locks = '$_apiVersion/locks';
  static const String emergencyUnlock = '$_apiVersion/locks/emergency-unlock';

  // ── Usage Tracking ────────────────────────────────────────────────────────
  static const String usageSync = '$_apiVersion/usage/sync';
  static const String usageReport = '$_apiVersion/usage/report';
  static const String usageSummary = '$_apiVersion/usage/summary';

  // ── Advanced Usage Tracking ───────────────────────────────────────────────
  static const String usageStatsMe = '$_apiVersion/usage/stats/me';
  static const String usageStatsGlobal = '$_apiVersion/usage/stats/global';
  static const String usageAppOpen = '$_apiVersion/usage/app-open';
  static const String usageAppClose = '$_apiVersion/usage/app-close';
  static const String usageHeartbeat = '$_apiVersion/usage/heartbeat';
  static const String usageEvents = '$_apiVersion/usage/events';
  static const String usageNotifications = '$_apiVersion/usage/notifications';
  static String usageNotificationDelivered(String deliveryId) => '$_apiVersion/usage/notifications/$deliveryId/delivered';
  static String usageNotificationOpened(String deliveryId) => '$_apiVersion/usage/notifications/$deliveryId/opened';

  // ── Breaches ──────────────────────────────────────────────────────────────
  static const String breaches = '$_apiVersion/breaches';
  static const String breachStreak = '$_apiVersion/breaches/streak';
  static const String breachScreenTime = '$_apiVersion/breaches/screen-time';
  static const String breachBlockedApp = '$_apiVersion/breaches/blocked-app';
  static String breachAcknowledge(String breachId) => '$_apiVersion/breaches/$breachId/acknowledge';
  static const String breachesMe = '$_apiVersion/breaches/me';
  static String breachesMeByType(String breachType) => '$_apiVersion/breaches/me/type/$breachType';

  /// Build a full URL from a relative endpoint path.
  static Uri uri(String endpoint) => Uri.parse('$baseUrl$endpoint');
}
