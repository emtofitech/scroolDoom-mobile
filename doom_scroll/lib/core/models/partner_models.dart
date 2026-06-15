import 'auth_models.dart';

class Partnership {
  final String id;
  final String status;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final UserProfile? partner;
  final UserProfile? createdBy;

  Partnership({
    required this.id,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    this.acceptedAt,
    this.partner,
    this.createdBy,
  });

  bool get isActive => status == 'active';

  factory Partnership.fromJson(Map<String, dynamic> json) {
    UserProfile? parseUser(dynamic value) =>
        value is Map<String, dynamic> ? UserProfile.fromJson(value) : null;

    return Partnership(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'])
          : null,
      partner: parseUser(json['partner']),
      createdBy: parseUser(json['createdBy']),
    );
  }
}
