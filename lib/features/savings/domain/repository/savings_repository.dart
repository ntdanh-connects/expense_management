import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';

abstract class SavingsRepository {
  Future<List<SavingsGoalEntity>> getSavingsGoals();

  Future<SavingsGoalEntity> createSavingsGoal({
    required String name,
    required double targetAmount,
    String? targetDate,
    String? autoSaveFrequency,
    double? autoSaveAmount,
    String? sourceWalletId,
  });

  Future<SavingsGoalEntity> getSavingsGoalDetail(String id);

  Future<SavingsGoalEntity> depositSavingsGoal({
    required String id,
    required double amount,
    required String sourceWalletId,
    String? notes,
  });

  Future<SavingsGoalEntity> withdrawSavingsGoal({
    required String id,
    required double amount,
    required String sourceWalletId,
    String? notes,
  });

  Future<void> deleteSavingsGoal(String id);
}
