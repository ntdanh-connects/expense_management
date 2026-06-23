import 'package:flutter/foundation.dart';
import 'package:expense_management/features/notification/data/di/data_providers.dart';
import 'package:expense_management/features/notification/data/datasource/remote/fcm_service.dart';
import 'package:expense_management/features/notification/data/repository_impl/notification_repository_impl.dart';
import 'package:expense_management/features/notification/domain/repositories/notification_repository.dart';
import 'package:expense_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  return NotificationRepositoryImpl(apiService);
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  final fcmService = FcmService(apiService, ref);
  fcmService.onDataChanged = () {
    try {
      ref.invalidate(fetchDashboardSummaryProvider);
      ref
          .read(fetchDashboardSummaryProvider.future)
          .then((_) {
            ref.invalidate(transactionListProvider);
            ref.invalidate(filteredTransactionListProvider);
            ref.read(notificationNotifierProvider.notifier).refresh();
          })
          .catchError((e) {
            debugPrint(
              "🚨 [FCM-Service] Error refreshing aggregate dashboard summary: $e",
            );
          });
    } catch (e) {
      debugPrint("🚨 [FCM-Service] Error in onDataChanged callback: $e");
    }
  };
  return fcmService;
});
