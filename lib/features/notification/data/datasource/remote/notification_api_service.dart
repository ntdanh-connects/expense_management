import 'package:dio/dio.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'notification_api_service.g.dart';

@RestApi()
abstract class NotificationApiService {
  factory NotificationApiService(Dio dio) = _NotificationApiService;

  @GET('api/notifications')
  Future<dynamic> getNotifications({
    @Query('page') int page = 1,
  });

  @POST('api/notifications/{id}/read')
  Future<void> markAsRead(@Path('id') String id);

  @POST('api/notifications/read-all')
  Future<void> markAllAsRead();

  @DELETE('api/notifications/{id}')
  Future<void> deleteNotification(@Path('id') String id);

  @GET('api/notifications/preferences')
  Future<dynamic> getPreferencesRaw();

  @POST('api/notifications/preferences')
  Future<dynamic> updatePreferencesRaw(@Body() Map<String, dynamic> body);

  @POST('api/user/device-token')
  Future<void> registerDeviceToken(@Body() Map<String, dynamic> body);

  @DELETE('api/user/device-token')
  Future<void> unregisterDeviceToken(@Body() Map<String, dynamic> body);
}
