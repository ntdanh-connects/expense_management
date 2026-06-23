import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/dashboard/data/datasource/remote/dashboard_api_service.dart';
import 'package:expense_management/features/dashboard/data/datasource/remote/recurring_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DashboardApiService(dio);
});

final recurringApiServiceProvider = Provider<RecurringApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return RecurringApiService(dio);
});
