import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  final String type;
  final String title;

  @JsonKey(name: 'content')
  final String body;

  @JsonKey(name: 'read_at')
  final String? readAt;

  final Map<String, dynamic>? metadata;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRead => readAt != null;

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final dto = _$NotificationDtoFromJson(json);
    
    dynamic metaValue = json['metadata'];
    Map<String, dynamic>? parsedMeta;
    if (metaValue is Map) {
      parsedMeta = Map<String, dynamic>.from(metaValue);
    } else if (metaValue is String && metaValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(metaValue);
        if (decoded is Map) {
          parsedMeta = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return NotificationDto(
      id: dto.id,
      userId: dto.userId,
      type: dto.type,
      title: dto.title,
      body: json['content'] as String? ?? json['body'] as String? ?? dto.body,
      readAt: dto.readAt,
      metadata: parsedMeta ?? dto.metadata,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);
}

@JsonSerializable()
class NotificationPreferenceDto {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'email_enabled')
  final bool emailEnabled;

  @JsonKey(name: 'push_enabled')
  final bool pushEnabled;

  @JsonKey(name: 'weekly_summary_enabled')
  final bool weeklySummaryEnabled;

  @JsonKey(name: 'daily_reminder_enabled')
  final bool dailyReminderEnabled;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  NotificationPreferenceDto({
    required this.id,
    required this.userId,
    required this.emailEnabled,
    required this.pushEnabled,
    required this.weeklySummaryEnabled,
    required this.dailyReminderEnabled,
    this.createdAt,
    this.updatedAt,
  });

  NotificationPreferenceDto copyWith({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? weeklySummaryEnabled,
    bool? dailyReminderEnabled,
  }) {
    return NotificationPreferenceDto(
      id: id,
      userId: userId,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory NotificationPreferenceDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferenceDtoToJson(this);
}
