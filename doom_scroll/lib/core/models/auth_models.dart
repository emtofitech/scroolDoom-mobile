/// Response model returned after a successful registration or login.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserProfile user;
  final List<ActiveLock> activeLocks;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
    required this.activeLocks,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponse(
      accessToken: d['accessToken'] ?? d['token'] ?? '',
      refreshToken: d['refreshToken'] ?? '',
      expiresIn: d['expiresIn'] ?? 0,
      user: UserProfile.fromJson(
        d['user'] is Map<String, dynamic> ? d['user']! : d,
      ),
      activeLocks: (d['activeLocks'] as List<dynamic>?)
              ?.map((e) => ActiveLock.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String timezone;
  final String username;
  final DateTime? createdAt;
  final String? displayName;
  final String? avatarUrl;
  final String? firebaseUid;

  UserProfile({
    required this.id,
    required this.email,
    required this.timezone,
    required this.username,
    this.createdAt,
    this.displayName,
    this.avatarUrl,
    this.firebaseUid,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? json['firebaseUid'] ?? '',
      email: json['email'] ?? '',
      timezone: json['timezone'] ?? '',
      username: json['username'] ?? json['displayName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      firebaseUid: json['firebaseUid'],
    );
  }
}

class ActiveLock {
  final String lockEventId;
  final String appId;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime? unlocksAt;
  final int secondsRemaining;
  final String lockReason;
  final int emergencyUnlocksUsedToday;
  final int emergencyUnlocksRemaining;
  final bool activeEmergencyWindow;

  ActiveLock({
    required this.lockEventId,
    required this.appId,
    required this.isLocked,
    this.lockedAt,
    this.unlocksAt,
    required this.secondsRemaining,
    required this.lockReason,
    required this.emergencyUnlocksUsedToday,
    required this.emergencyUnlocksRemaining,
    required this.activeEmergencyWindow,
  });

  factory ActiveLock.fromJson(Map<String, dynamic> json) {
    return ActiveLock(
      lockEventId: json['lockEventId'] ?? '',
      appId: json['appId'] ?? '',
      isLocked: json['isLocked'] ?? false,
      lockedAt: json['lockedAt'] != null
          ? DateTime.tryParse(json['lockedAt'])
          : null,
      unlocksAt: json['unlocksAt'] != null
          ? DateTime.tryParse(json['unlocksAt'])
          : null,
      secondsRemaining: json['secondsRemaining'] ?? 0,
      lockReason: json['lockReason'] ?? '',
      emergencyUnlocksUsedToday: json['emergencyUnlocksUsedToday'] ?? 0,
      emergencyUnlocksRemaining: json['emergencyUnlocksRemaining'] ?? 0,
      activeEmergencyWindow: json['activeEmergencyWindow'] ?? false,
    );
  }
}
