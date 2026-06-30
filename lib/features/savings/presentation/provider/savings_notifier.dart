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

  static List<SavingsGoalEntity>? _cachedList;
  static DateTime? _lastFetchTime;

  SavingsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals({bool silent = false, bool force = false}) async {
    final now = DateTime.now();
    if (!force && _cachedList != null && _lastFetchTime != null && now.difference(_lastFetchTime!) < const Duration(seconds: 15)) {
      state = AsyncValue.data(_cachedList!);
      return;
    }

    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      final list = await _repository.getSavingsGoals();
      _cachedList = list;
      _lastFetchTime = DateTime.now();
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
      await loadGoals(silent: true, force: true);
      return goal;
    } catch (e, st) {
      logException(e, st, tag: 'SavingsListNotifier_createGoal');
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteSavingsGoal(id);
      await loadGoals(silent: true, force: true);
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

  static final Map<String, SavingsGoalEntity> _cachedDetails = {};
  static final Map<String, DateTime> _lastDetailFetchTimes = {};

  SavingsDetailNotifier(this._repository, this._id) : super(const AsyncValue.loading()) {
    loadDetail();
  }

  Future<void> loadDetail({bool force = false}) async {
    final now = DateTime.now();
    final cached = _cachedDetails[_id];
    final lastFetch = _lastDetailFetchTimes[_id];
    if (!force && cached != null && lastFetch != null && now.difference(lastFetch) < const Duration(seconds: 15)) {
      state = AsyncValue.data(cached);
      return;
    }

    try {
      final goal = await _repository.getSavingsGoalDetail(_id);
      _cachedDetails[_id] = goal;
      _lastDetailFetchTimes[_id] = DateTime.now();
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
      _cachedDetails[_id] = updated;
      _lastDetailFetchTimes[_id] = DateTime.now();
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
      _cachedDetails[_id] = updated;
      _lastDetailFetchTimes[_id] = DateTime.now();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      logException(e, st, tag: 'SavingsDetailNotifier_withdraw');
      rethrow;
    }
  }
}
