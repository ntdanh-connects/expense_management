import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:expense_management/features/dashboard/data/datasource/remote/dashboard_api_service.dart';
import 'package:expense_management/features/dashboard/data/repository_impl/dashboard_repository_impl.dart';
import 'package:expense_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:expense_management/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DashboardApiService(dio);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiService = ref.watch(dashboardApiServiceProvider);
  final walletLocalDataSource = ref.watch(walletLocalDataSourceProvider);
  final database = ref.watch(appDatabaseProvider);
  return DashboardRepositoryImpl(
    apiService,
    walletLocalDataSource,
    database,
    () => ref.read(currentUserProvider)?.id ?? '',
  );
});

// Provider gọi API aggregate để fetch & sync toàn bộ Dashboard data
final fetchDashboardSummaryProvider = FutureProvider<DashboardSummaryDto>((ref) async {
  ref.watch(transactionListProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getSummary();
});
