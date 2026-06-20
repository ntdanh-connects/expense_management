import 'package:dio/dio.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/notification/data/datasource/remote/notification_api_service.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:expense_management/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApiService _apiService;

  NotificationRepositoryImpl(this._apiService);

  @override
  Future<List<NotificationDto>> getNotifications({int page = 1}) async {
    try {
      final response = await _apiService.getNotifications(page: page) as Map<String, dynamic>;
      final items = (response['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] getNotifications: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] getNotifications unknown: $e',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications(page: 1);
      return notifications.where((n) => !n.isRead).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _apiService.markAsRead(id);
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] markAsRead: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllAsRead();
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] markAllAsRead: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _apiService.deleteNotification(id);
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] deleteNotification: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      await _apiService.clearAllNotifications();
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] clearAllNotifications: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<NotificationPreferenceDto> getPreferences() async {
    try {
      final response = await _apiService.getPreferencesRaw() as Map<String, dynamic>;
      final data = response['data'];
      return NotificationPreferenceDto.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] getPreferences: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<NotificationPreferenceDto> updatePreferences({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? weeklySummaryEnabled,
    bool? dailyReminderEnabled,
  }) async {
    try {
      final body = <String, dynamic>{
        if (emailEnabled != null) 'email_enabled': emailEnabled,
        if (pushEnabled != null) 'push_enabled': pushEnabled,
        if (weeklySummaryEnabled != null)
          'weekly_summary_enabled': weeklySummaryEnabled,
        if (dailyReminderEnabled != null)
          'daily_reminder_enabled': dailyReminderEnabled,
      };
      final response = await _apiService.updatePreferencesRaw(body) as Map<String, dynamic>;
      final data = response['data'];
      return NotificationPreferenceDto.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [Notification-Repo] updatePreferences: ${e.message}',
        tag: 'Notification',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
