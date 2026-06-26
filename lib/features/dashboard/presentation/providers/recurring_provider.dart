import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/domain/di/domain_providers.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/error/error_handler_mixin.dart';

// ─── Notifier ───────────────────────────────────────────────────

class RecurringNotifier extends AsyncNotifier<List<RecurringRuleEntity>> with ErrorHandlerMixin {
  @override
  Future<List<RecurringRuleEntity>> build() async {
    final rules = await ref.watch(getRulesUseCaseProvider).execute();
    _updateNotifications(rules);
    return rules;
  }

  Future<void> _updateNotifications(List<RecurringRuleEntity> rules) async {
    try {
      final pref = ref.read(notificationPreferencesProvider).value;
      final isPushEnabled = pref?.pushEnabled ?? true;
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      for (final rule in rules) {
        final id = rule.id.hashCode;
        await LocalNotificationService.cancelNotification(id);
        if (userId.isNotEmpty) {
          await LocalNotificationStorage.deleteNotification(userId, 'local_recurring_${rule.id}');
        }
        if (isPushEnabled && rule.isActive && rule.nextRunAt != null) {
          final targetDate = rule.nextRunAt!.subtract(const Duration(days: 1));
          if (targetDate.isAfter(DateTime.now())) {
            await LocalNotificationService.scheduleNotification(
              id: id,
              title: 'Nhắc nhở giao dịch định kỳ sắp tới',
              body: 'Giao dịch "${rule.title}" với số tiền ${rule.amount.toStringAsFixed(0)} đ sẽ được thực hiện vào ngày mai.',
              scheduledDate: targetDate,
            );
            if (userId.isNotEmpty) {
              final localNotif = NotificationDto(
                id: 'local_recurring_${rule.id}',
                userId: userId,
                type: 'recurring_created',
                title: 'Nhắc nhở giao dịch định kỳ sắp tới',
                body: 'Giao dịch "${rule.title}" với số tiền ${rule.amount.toStringAsFixed(0)} đ sẽ được thực hiện vào ngày mai.',
                createdAt: targetDate.toIso8601String(),
                updatedAt: targetDate.toIso8601String(),
              );
              await LocalNotificationStorage.saveNotification(userId, localNotif);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _cancelNotification(String id) async {
    try {
      await LocalNotificationService.cancelNotification(id.hashCode);
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      if (userId.isNotEmpty) {
        await LocalNotificationStorage.deleteNotification(userId, 'local_recurring_$id');
      }
    } catch (_) {}
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    final newState = await AsyncValue.guard(() async {
      final rules = await ref.read(getRulesUseCaseProvider).execute();
      _updateNotifications(rules);
      return rules;
    });
    if (silent && newState.hasError && state.hasValue) {
      return;
    }
    state = newState;
  }

  Future<void> createRule(Map<String, dynamic> data) async {
    final rule = await ref.read(createRuleUseCaseProvider).execute(data);
    state = AsyncValue.data([rule, ...(state.value ?? [])]);
    _updateNotifications([rule]);
  }

  Future<void> updateRule(String id, Map<String, dynamic> data) async {
    final updated = await ref.read(updateRuleUseCaseProvider).execute(id, data);
    state = AsyncValue.data(
      (state.value ?? []).map((r) => r.id == id ? updated : r).toList(),
    );
    _updateNotifications([updated]);
  }

  Future<void> deleteRule(String id) async {
    await ref.read(deleteRuleUseCaseProvider).execute(id);
    state = AsyncValue.data((state.value ?? []).where((r) => r.id != id).toList());
    _cancelNotification(id);
  }

  Future<void> toggleRule(String id) async {
    final toggled = await ref.read(toggleRuleUseCaseProvider).execute(id);
    state = AsyncValue.data(
      (state.value ?? []).map((r) => r.id == id ? toggled : r).toList(),
    );
    _updateNotifications([toggled]);
  }
}

final recurringNotifierProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringRuleEntity>>(
  RecurringNotifier.new,
);