/// A single app limit as returned by the API.
class AppLimit {
  final String id;
  final String packageName;
  final String appLabel;
  final int dailyLimitMinutes;
  final bool isActive;
  final int todayUsageSeconds;

  AppLimit({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.dailyLimitMinutes,
    this.isActive = true,
    this.todayUsageSeconds = 0,
  });

  factory AppLimit.fromJson(Map<String, dynamic> json) {
    return AppLimit(
      id: json['id'] ?? '',
      packageName: json['packageName'] ?? '',
      appLabel: json['appLabel'] ?? '',
      dailyLimitMinutes: json['dailyLimitMinutes'] ?? 0,
      isActive: json['isActive'] ?? true,
      todayUsageSeconds: json['todayUsageSeconds'] ?? 0,
    );
  }

  /// Backward compatibility getters for UI convenience:
  String get appId => packageName;
  int get dailyLimitSeconds => dailyLimitMinutes * 60;
  int get limitMinutes => dailyLimitMinutes;

  /// Today's usage expressed in minutes.
  int get usageMinutes => todayUsageSeconds ~/ 60;

  /// Progress ratio (0.0 – 1.0+). Can exceed 1 if user went over limit.
  double get progress =>
      dailyLimitSeconds > 0 ? todayUsageSeconds / dailyLimitSeconds : 0.0;

  /// Human-readable formatted time, e.g. "1h 30m".
  static String formatMinutes(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }
}
