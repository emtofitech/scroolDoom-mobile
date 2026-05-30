enum BreachType {
  blockedAppOpened,
  screenTimeExceeded,
  streakBroken;

  String get apiValue {
    switch (this) {
      case BreachType.blockedAppOpened:
        return 'BLOCKED_APP_OPENED';
      case BreachType.screenTimeExceeded:
        return 'SCREEN_TIME_EXCEEDED';
      case BreachType.streakBroken:
        return 'STREAK_BROKEN';
    }
  }

  static BreachType fromApi(String value) {
    switch (value) {
      case 'BLOCKED_APP_OPENED':
        return BreachType.blockedAppOpened;
      case 'SCREEN_TIME_EXCEEDED':
        return BreachType.screenTimeExceeded;
      case 'STREAK_BROKEN':
        return BreachType.streakBroken;
      default:
        return BreachType.blockedAppOpened;
    }
  }
}

class Breach {
  final String id;
  final BreachType breachType;
  final String? packageName;
  final String? appLabel;
  final int? limitMinutes;
  final int? actualMinutes;
  final String? streakName;
  final int? missedDays;
  final String severity;
  final bool partnerNotified;
  final bool acknowledged;
  final DateTime breachedAt;

  Breach({
    required this.id,
    required this.breachType,
    this.packageName,
    this.appLabel,
    this.limitMinutes,
    this.actualMinutes,
    this.streakName,
    this.missedDays,
    required this.severity,
    required this.partnerNotified,
    required this.acknowledged,
    required this.breachedAt,
  });

  factory Breach.fromJson(Map<String, dynamic> json) {
    return Breach(
      id: json['id'] ?? '',
      breachType: BreachType.fromApi(json['breachType'] ?? ''),
      packageName: json['packageName'],
      appLabel: json['appLabel'],
      limitMinutes: json['limitMinutes'],
      actualMinutes: json['actualMinutes'],
      streakName: json['streakName'],
      missedDays: json['missedDays'],
      severity: json['severity'] ?? 'LOW',
      partnerNotified: json['partnerNotified'] ?? false,
      acknowledged: json['acknowledged'] ?? false,
      breachedAt: DateTime.tryParse(json['breachedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
