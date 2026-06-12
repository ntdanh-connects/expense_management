import 'package:expense_management/features/notification/data/models/notification_dto.dart';

abstract class NotificationRepository {
  Future<List<NotificationDto>> getNotifications({int page = 1});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<NotificationPreferenceDto> getPreferences();
  Future<NotificationPreferenceDto> updatePreferences({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? weeklySummaryEnabled,
    bool? dailyReminderEnabled,
  });
}
