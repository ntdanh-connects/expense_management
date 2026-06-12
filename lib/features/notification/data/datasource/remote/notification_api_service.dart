import 'package:dio/dio.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  /// GET /api/notifications?page=X
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await _dio.get(
      'api/notifications',
      queryParameters: {'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/notifications/{id}/read
  Future<void> markAsRead(String id) async {
    await _dio.post('api/notifications/$id/read');
  }

  /// POST /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _dio.post('api/notifications/read-all');
  }

  /// DELETE /api/notifications/{id}
  Future<void> deleteNotification(String id) async {
    await _dio.delete('api/notifications/$id');
  }

  /// GET /api/notifications/preferences
  Future<NotificationPreferenceDto> getPreferences() async {
    final response = await _dio.get('api/notifications/preferences');
    final data = (response.data as Map<String, dynamic>)['data'];
    return NotificationPreferenceDto.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/notifications/preferences
  Future<NotificationPreferenceDto> updatePreferences(
      Map<String, dynamic> body) async {
    final response = await _dio.post(
      'api/notifications/preferences',
      data: body,
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return NotificationPreferenceDto.fromJson(data as Map<String, dynamic>);
  }
}
