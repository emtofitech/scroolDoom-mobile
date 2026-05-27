/// A single app limit as returned by the API.
class AppLimit {
  final String id;
  final String appId;
  final int dailyLimitSeconds;
  final bool isActive;
  final int todayUsageSeconds;

  AppLimit({
    required this.id,
    required this.appId,
    required this.dailyLimitSeconds,
    required this.isActive,
    required this.todayUsageSeconds,
  });

  factory AppLimit.fromJson(Map<String, dynamic> json) {
    return AppLimit(
      id: json['id'] ?? '',
      appId: json['appId'] ?? '',
      dailyLimitSeconds: json['dailyLimitSeconds'] ?? 0,
      isActive: json['isActive'] ?? true,
      todayUsageSeconds: json['todayUsageSeconds'] ?? 0,
    );
  }

  /// Daily limit expressed in minutes (for UI convenience).
  int get limitMinutes => dailyLimitSeconds ~/ 60;

  /// Today's usage expressed in minutes.
  int get usageMinutes => todayUsageSeconds ~/ 60;

  /// Progress ratio (0.0 – 1.0+). Can exceed 1 if user went over limit.
  double get progress =>
      dailyLimitSeconds > 0 ? todayUsageSeconds / dailyLimitSeconds : 0;

  /// Human-readable formatted time, e.g. "1h 30m".
  static String formatMinutes(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }
}
