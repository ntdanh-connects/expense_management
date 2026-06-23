import 'package:expense_management/core/error/error_handler_mixin.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';
import 'package:expense_management/features/savings/domain/repository/savings_repository.dart';
import 'package:expense_management/features/savings/domain/di/domain_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final savingsListProvider = StateNotifierProvider<SavingsListNotifier, AsyncValue<List<SavingsGoalEntity>>>((ref) {
  final repo = ref.watch(savingsRepositoryProvider);
  return SavingsListNotifier(repo);
});

class SavingsListNotifier extends StateNotifier<AsyncValue<List<SavingsGoalEntity>>> with ErrorHandlerMixin {
  final SavingsRepository _repository;

  SavingsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getSavingsGoals();
      state = AsyncValue.data(list);
    } catch (e, st) {
      logException(e, st, tag: 'SavingsListNotifier_loadGoals');
      state = AsyncValue.error(e, st);
    }
  }

  Future<SavingsGoalEntity> createGoal({
    required String name,
    required double targetAmount,
    String? targetDate,
    String? autoSaveFrequency,
    double? autoSaveAmount,
    String? sourceWalletId,
  }) async {
    try {
      final goal = await _repository.createSavingsGoal(
        name: name,
        targetAmount: targetAmount,
        targetDate: targetDate,
        autoSaveFrequency: autoSaveFrequency,
        autoSaveAmount: autoSaveAmount,
        sourceWalletId: sourceWalletId,
      );
      await loadGoals();
      return goal;
    } catch (e, st) {
      logException(e, st, tag: 'SavingsListNotifier_createGoal');
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteSavingsGoal(id);
      await loadGoals();
    } catch (e, st) {
      logException(e, st, tag: 'SavingsListNotifier_deleteGoal');
      rethrow;
    }
  }
}

final savingsDetailProvider = StateNotifierProvider.family<SavingsDetailNotifier, AsyncValue<SavingsGoalEntity>, String>((ref, id) {
  final repo = ref.watch(savingsRepositoryProvider);
  return SavingsDetailNotifier(repo, id);
});

class SavingsDetailNotifier extends StateNotifier<AsyncValue<SavingsGoalEntity>> with ErrorHandlerMixin {
  final SavingsRepository _repository;
  final String _id;

  SavingsDetailNotifier(this._repository, this._id) : super(const AsyncValue.loading()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final goal = await _repository.getSavingsGoalDetail(_id);
      state = AsyncValue.data(goal);
    } catch (e, st) {
      logException(e, st, tag: 'SavingsDetailNotifier_loadDetail');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deposit({
    required double amount,
    required String sourceWalletId,
    String? notes,
  }) async {
    try {
      final updated = await _repository.depositSavingsGoal(
        id: _id,
        amount: amount,
        sourceWalletId: sourceWalletId,
        notes: notes,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      logException(e, st, tag: 'SavingsDetailNotifier_deposit');
      rethrow;
    }
  }

  Future<void> withdraw({
    required double amount,
    required String sourceWalletId,
    String? notes,
  }) async {
    try {
      final updated = await _repository.withdrawSavingsGoal(
        id: _id,
        amount: amount,
        sourceWalletId: sourceWalletId,
        notes: notes,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      logException(e, st, tag: 'SavingsDetailNotifier_withdraw');
      rethrow;
    }
  }
}
