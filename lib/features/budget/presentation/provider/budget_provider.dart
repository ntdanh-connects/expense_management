import 'dart:async';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_management/features/budget/data/repository_impl/budget_repository_impl.dart';
import 'package:expense_management/features/budget/data/data_source/remote/budget_api_service.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final budgetApiServiceProvider = Provider<BudgetApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return BudgetApiService(dio);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final apiService = ref.watch(budgetApiServiceProvider);
  return BudgetRepositoryImpl(apiService);
});

final selectedBudgetMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedBudgetYearProvider = StateProvider<int>((ref) => DateTime.now().year);

class BudgetListNotifier extends AsyncNotifier<List<BudgetDto>> {
  @override
  FutureOr<List<BudgetDto>> build() async {
    final month = ref.watch(selectedBudgetMonthProvider);
    final year = ref.watch(selectedBudgetYearProvider);
    return _fetchBudgets(month, year);
  }

  Future<List<BudgetDto>> _fetchBudgets(int month, int year) async {
    final repository = ref.read(budgetRepositoryProvider);
    return repository.getBudgets(month, year);
  }

  Future<void> refreshBudgets() async {
    ref.invalidate(currentMonthBudgetsProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final month = ref.read(selectedBudgetMonthProvider);
      final year = ref.read(selectedBudgetYearProvider);
      return _fetchBudgets(month, year);
    });
  }

  Future<void> createOrUpdateBudget({
    String? categoryId,
    required double limitAmount,
  }) async {
    final month = ref.read(selectedBudgetMonthProvider);
    final year = ref.read(selectedBudgetYearProvider);
    final repository = ref.read(budgetRepositoryProvider);
    
    await repository.createOrUpdateBudget(
      categoryId: categoryId,
      limitAmount: limitAmount,
      month: month,
      year: year,
    );
    await refreshBudgets();
  }

  Future<void> deleteBudget(String id) async {
    final repository = ref.read(budgetRepositoryProvider);
    await repository.deleteBudget(id);
    await refreshBudgets();
  }

  Future<void> copyFromPreviousMonth() async {
    final month = ref.read(selectedBudgetMonthProvider);
    final year = ref.read(selectedBudgetYearProvider);
    
    int fromMonth = month - 1;
    int fromYear = year;
    if (fromMonth == 0) {
      fromMonth = 12;
      fromYear = year - 1;
    }

    final repository = ref.read(budgetRepositoryProvider);
    await repository.copyBudgets(
      fromMonth: fromMonth,
      fromYear: fromYear,
      toMonth: month,
      toYear: year,
    );
    await refreshBudgets();
  }
}

final budgetListProvider = AsyncNotifierProvider<BudgetListNotifier, List<BudgetDto>>(() {
  return BudgetListNotifier();
});

final currentMonthBudgetsProvider = FutureProvider<List<BudgetDto>>((ref) async {
  final now = DateTime.now();
  final repository = ref.read(budgetRepositoryProvider);
  return repository.getBudgets(now.month, now.year);
});
