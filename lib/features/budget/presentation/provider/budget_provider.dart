import 'dart:async';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_management/features/budget/data/repository_impl/budget_repository_impl.dart';
import 'package:expense_management/features/budget/data/data_source/remote/budget_api_service.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';

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
    final budgets = await repository.getBudgets(month, year);
    return _overrideBudgetUsages(ref, budgets, month, year);
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
  final budgets = await repository.getBudgets(now.month, now.year);
  return _overrideBudgetUsages(ref, budgets, now.month, now.year);
});

Future<List<BudgetDto>> _overrideBudgetUsages(Ref ref, List<BudgetDto> budgets, int month, int year) async {
  try {
    final reportRepo = ref.read(reportRepositoryProvider);
    final report = await reportRepo.getCategories(
      month: month,
      year: year,
      type: 'expense',
    );

    final updatedBudgets = budgets.map((b) {
      if (b.categoryId == null) {
        return b;
      } else {
        // Sum category and subcategory spending amounts from the report
        final matchingEntries = report.categories.where((e) =>
            e.categoryId == b.categoryId || e.parentId == b.categoryId);
        final used = matchingEntries.fold<double>(0.0, (sum, e) => sum + e.amount);
        return b.copyWith(usedAmount: used);
      }
    }).toList();

    return _recalculateOverallBudgetUsage(updatedBudgets, report.totalAmount);
  } catch (e) {
    return _recalculateOverallBudgetUsage(budgets, 0.0);
  }
}

List<BudgetDto> _recalculateOverallBudgetUsage(List<BudgetDto> budgets, double fallbackTotal) {
  final generalIndex = budgets.indexWhere((b) => b.categoryId == null);
  final categories = budgets.where((b) => b.categoryId != null).toList();
  if (generalIndex != -1) {
    final general = budgets[generalIndex];
    double sumUsed = 0.0;
    if (categories.isNotEmpty) {
      sumUsed = categories.fold<double>(0.0, (sum, b) => sum + b.usedAmount);
    } else {
      sumUsed = fallbackTotal > 0.0 ? fallbackTotal : general.usedAmount;
    }
    final mutableBudgets = List<BudgetDto>.from(budgets);
    mutableBudgets[generalIndex] = general.copyWith(usedAmount: sumUsed);
    return mutableBudgets;
  }
  return budgets;
}
