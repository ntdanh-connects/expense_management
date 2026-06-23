import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/wallet/data/di/data_providers.dart';
import 'package:expense_management/features/dashboard/data/di/data_providers.dart';
import 'package:expense_management/features/dashboard/data/repository_impl/dashboard_repository_impl.dart';
import 'package:expense_management/features/dashboard/data/repository_impl/recurring_repository_impl.dart';
import 'package:expense_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:expense_management/features/dashboard/domain/repositories/recurring_repository.dart';
import 'package:expense_management/features/dashboard/domain/use_case/recurring_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final apiService = ref.watch(recurringApiServiceProvider);
  return RecurringRepositoryImpl(apiService);
});

final getRulesUseCaseProvider = Provider<GetRecurringRulesUseCase>((ref) {
  return GetRecurringRulesUseCase(ref.watch(recurringRepositoryProvider));
});

final createRuleUseCaseProvider = Provider<CreateRecurringRuleUseCase>((ref) {
  return CreateRecurringRuleUseCase(ref.watch(recurringRepositoryProvider));
});

final updateRuleUseCaseProvider = Provider<UpdateRecurringRuleUseCase>((ref) {
  return UpdateRecurringRuleUseCase(ref.watch(recurringRepositoryProvider));
});

final deleteRuleUseCaseProvider = Provider<DeleteRecurringRuleUseCase>((ref) {
  return DeleteRecurringRuleUseCase(ref.watch(recurringRepositoryProvider));
});

final toggleRuleUseCaseProvider = Provider<ToggleRecurringRuleUseCase>((ref) {
  return ToggleRecurringRuleUseCase(ref.watch(recurringRepositoryProvider));
});
