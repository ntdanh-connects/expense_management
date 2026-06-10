import 'package:expense_management/features/budget/data/models/budget_dto.dart';

abstract class BudgetRepository {
  Future<List<BudgetDto>> getBudgets(int month, int year);
  Future<BudgetDto> createOrUpdateBudget({
    String? categoryId,
    required double limitAmount,
    required int month,
    required int year,
  });
  Future<void> deleteBudget(String id);
  Future<List<BudgetDto>> copyBudgets({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  });
}
