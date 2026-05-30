class LimitStatus {
  final String id;
  final String packageName;
  final String appLabel;
  final int dailyLimitMinutes;
  final bool exceeded;
  final int actualMinutes;
  final int remainingMinutes;

  LimitStatus({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.dailyLimitMinutes,
    required this.exceeded,
    required this.actualMinutes,
    required this.remainingMinutes,
  });

  factory LimitStatus.fromJson(Map<String, dynamic> json) {
    return LimitStatus(
      id: json['id'] ?? '',
      packageName: json['packageName'] ?? '',
      appLabel: json['appLabel'] ?? '',
      dailyLimitMinutes: json['dailyLimitMinutes'] ?? 0,
      exceeded: json['exceeded'] ?? false,
      actualMinutes: json['actualMinutes'] ?? 0,
      remainingMinutes: json['remainingMinutes'] ?? 0,
    );
  }

  int get actualSeconds => actualMinutes * 60;
  int get dailyLimitSeconds => dailyLimitMinutes * 60;

  double get progress =>
      dailyLimitSeconds > 0 ? actualSeconds / dailyLimitSeconds : 0.0;
}
