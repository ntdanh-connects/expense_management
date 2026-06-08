import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/dashboard/data/datasource/remote/recurring_api_service.dart';
import 'package:expense_management/features/dashboard/data/repository_impl/recurring_repository_impl.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/domain/repositories/recurring_repository.dart';
import 'package:expense_management/features/dashboard/domain/use_case/recurring_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── DI Providers ───────────────────────────────────────────────

final recurringApiServiceProvider = Provider<RecurringApiService>((ref) {
  return RecurringApiService(ref.watch(dioClientProvider));
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepositoryImpl(ref.watch(recurringApiServiceProvider));
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

// ─── Notifier ───────────────────────────────────────────────────

class RecurringNotifier extends AsyncNotifier<List<RecurringRuleEntity>> {
  @override
  Future<List<RecurringRuleEntity>> build() async {
    return ref.read(getRulesUseCaseProvider).execute();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(getRulesUseCaseProvider).execute());
  }

  Future<void> createRule(Map<String, dynamic> data) async {
    final rule = await ref.read(createRuleUseCaseProvider).execute(data);
    state = AsyncValue.data([rule, ...(state.value ?? [])]);
  }

  Future<void> updateRule(String id, Map<String, dynamic> data) async {
    final updated = await ref.read(updateRuleUseCaseProvider).execute(id, data);
    state = AsyncValue.data(
      (state.value ?? []).map((r) => r.id == id ? updated : r).toList(),
    );
  }

  Future<void> deleteRule(String id) async {
    await ref.read(deleteRuleUseCaseProvider).execute(id);
    state = AsyncValue.data((state.value ?? []).where((r) => r.id != id).toList());
  }

  Future<void> toggleRule(String id) async {
    final toggled = await ref.read(toggleRuleUseCaseProvider).execute(id);
    state = AsyncValue.data(
      (state.value ?? []).map((r) => r.id == id ? toggled : r).toList(),
    );
  }
}

final recurringNotifierProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringRuleEntity>>(
  RecurringNotifier.new,
);