class UserSessionDto {
  final String id;
  final String deviceType;
  final String deviceName;
  final String ipAddress;
  final String userAgent;
  final String createdAt;
  final String expiredAt;
  final bool isCurrent;

  UserSessionDto({
    required this.id,
    required this.deviceType,
    required this.deviceName,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.expiredAt,
    required this.isCurrent,
  });

  factory UserSessionDto.fromJson(Map<String, dynamic> json) {
    return UserSessionDto(
      id: json['id'] as String,
      deviceType: json['device_type'] as String? ?? 'unknown',
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      ipAddress: json['ip_address'] as String? ?? '',
      userAgent: json['user_agent'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      expiredAt: json['expired_at'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_type': deviceType,
      'device_name': deviceName,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt,
      'expired_at': expiredAt,
      'is_current': isCurrent,
    };
  }
}
