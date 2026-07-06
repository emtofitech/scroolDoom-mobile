// ── Usage Sync ────────────────────────────────────────────────────────────────

/// Payload item for POST /api/v1/usage/sync
class UsageSyncEntry {
  final String appId;
  final int usageSeconds;
  final String date; // yyyy-MM-dd

  const UsageSyncEntry({
    required this.appId,
    required this.usageSeconds,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'usageSeconds': usageSeconds,
        'date': date,
      };
}

/// Response data from POST /api/v1/usage/sync
class UsageSyncResult {
  final int synced;

  const UsageSyncResult({required this.synced});

  factory UsageSyncResult.fromJson(Map<String, dynamic> json) =>
      UsageSyncResult(synced: (json['synced'] as num?)?.toInt() ?? 0);
}

/// Warning returned when an app is approaching its daily limit.
class UsageWarning {
  final String appId;
  final int warningLevel; // e.g. 1 = 60%, 2 = 90%
  final int usageSeconds;

  const UsageWarning({
    required this.appId,
    required this.warningLevel,
    required this.usageSeconds,
  });

  factory UsageWarning.fromJson(Map<String, dynamic> json) => UsageWarning(
        appId: json['appId'] as String? ?? '',
        warningLevel: (json['warningLevel'] as num?)?.toInt() ?? 0,
        usageSeconds: (json['usageSeconds'] as num?)?.toInt() ?? 0,
      );
}

/// A lock that was triggered because the app exceeded its daily limit.
class NewLock {
  final String appId;
  final String appLabel;
  final String lockEventId;
  final DateTime lockedUntil;

  const NewLock({
    required this.appId,
    this.appLabel = '',
    required this.lockEventId,
    required this.lockedUntil,
  });

  factory NewLock.fromJson(Map<String, dynamic> json) => NewLock(
        appId: json['appId'] as String? ?? '',
        appLabel: json['appLabel'] as String? ?? '',
        lockEventId: json['lockEventId'] as String? ?? '',
        lockedUntil: DateTime.tryParse(
                json['lockedUntil'] as String? ?? '') ??
            DateTime.now(),
      );
}

// ── Usage Summary ─────────────────────────────────────────────────────────────

/// Per-device breakdown within a summary entry.
class DeviceUsageBreakdown {
  final String deviceId;
  final int seconds;

  const DeviceUsageBreakdown({
    required this.deviceId,
    required this.seconds,
  });

  factory DeviceUsageBreakdown.fromJson(Map<String, dynamic> json) =>
      DeviceUsageBreakdown(
        deviceId: json['deviceId'] as String? ?? '',
        seconds: (json['seconds'] as num?)?.toInt() ?? 0,
      );
}

/// One app's entry in the GET /api/v1/usage/summary response.
class UsageSummaryEntry {
  final String appId;
  final int totalSeconds;
  final List<DeviceUsageBreakdown> deviceBreakdown;

  const UsageSummaryEntry({
    required this.appId,
    required this.totalSeconds,
    required this.deviceBreakdown,
  });

  /// Convenience: total in minutes.
  int get totalMinutes => totalSeconds ~/ 60;

  factory UsageSummaryEntry.fromJson(Map<String, dynamic> json) =>
      UsageSummaryEntry(
        appId: json['appId'] as String? ?? '',
        totalSeconds: (json['totalSeconds'] as num?)?.toInt() ?? 0,
        deviceBreakdown: (json['deviceBreakdown'] as List<dynamic>?)
                ?.map((e) =>
                    DeviceUsageBreakdown.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
