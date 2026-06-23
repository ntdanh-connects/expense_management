import 'package:expense_management/features/budget/data/di/data_providers.dart';
import 'package:expense_management/features/budget/data/repository_impl/budget_repository_impl.dart';
import 'package:expense_management/features/budget/domain/repositories/budget_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final apiService = ref.watch(budgetApiServiceProvider);
  return BudgetRepositoryImpl(apiService);
});
