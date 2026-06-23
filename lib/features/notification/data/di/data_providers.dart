import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/notification/data/datasource/remote/notification_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return NotificationApiService(dio);
});
