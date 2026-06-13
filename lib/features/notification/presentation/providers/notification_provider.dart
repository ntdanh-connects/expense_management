import 'dart:async';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/notification/data/datasource/remote/notification_api_service.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:expense_management/features/notification/data/repository_impl/notification_repository_impl.dart';
import 'package:expense_management/features/notification/domain/repositories/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/notification/data/datasource/remote/fcm_service.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Service & Repository providers
// ---------------------------------------------------------------------------

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return NotificationApiService(dio);
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  final fcmService = FcmService(apiService);
  fcmService.onDataChanged = () {
    try {
      ref.read(transactionListProvider.notifier).refreshTransactions(silent: true);
      ref.read(filteredTransactionListProvider.notifier).refreshTransactions(silent: true);
      ref.read(walletNotifierProvider.notifier).refreshWallets();
      ref.invalidate(budgetListProvider);
      ref.invalidate(currentMonthBudgetsProvider);
      ref.read(notificationNotifierProvider.notifier).refresh();
    } catch (e) {
      debugPrint("🚨 [FCM-Service] Error refreshing data on notification: $e");
    }
  };
  return fcmService;
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  return NotificationRepositoryImpl(apiService);
});

// ---------------------------------------------------------------------------
// Notification list state
// ---------------------------------------------------------------------------

class NotificationState {
  final List<NotificationDto> notifications;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationDto>? notifications,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  @override
  FutureOr<NotificationState> build() async {
    return _fetchPage(1, []);
  }

  Future<NotificationState> _fetchPage(
      int page, List<NotificationDto> existing) async {
    final repo = ref.read(notificationRepositoryProvider);
    
    List<NotificationDto> remoteItems = [];
    try {
      remoteItems = await repo.getNotifications(page: page);
    } catch (_) {
      // Gracefully handle remote errors so local notifications can still be displayed
    }
    
    // Fetch local notifications if this is the first page
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? '';
    List<NotificationDto> localItems = [];
    if (userId.isNotEmpty && page == 1) {
      final allLocal = await LocalNotificationStorage.getNotifications(userId);
      final now = DateTime.now();
      localItems = allLocal.where((n) {
        try {
          final dt = DateTime.parse(n.createdAt);
          return dt.isBefore(now) || dt.isAtSameMomentAs(now);
        } catch (_) {
          return true;
        }
      }).toList();
    }

    final merged = [...localItems, ...existing, ...remoteItems];
    
    // Remove duplicates by ID just in case
    final seen = <String>{};
    final uniqueMerged = <NotificationDto>[];
    for (final item in merged) {
      if (seen.add(item.id)) {
        uniqueMerged.add(item);
      }
    }
    
    // Sort chronologically descending
    uniqueMerged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return NotificationState(
      notifications: uniqueMerged,
      isLoading: false,
      hasMore: remoteItems.length >= 15,
      currentPage: page,
    );
  }

  void addLocalNotification(NotificationDto notif) {
    final current = state.value;
    if (current == null) return;
    
    final merged = [notif, ...current.notifications];
    final seen = <String>{};
    final uniqueMerged = <NotificationDto>[];
    for (final item in merged) {
      if (seen.add(item.id)) {
        uniqueMerged.add(item);
      }
    }
    uniqueMerged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncValue.data(current.copyWith(notifications: uniqueMerged));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(1, []));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoading) return;

    state = AsyncValue.data(current.copyWith(isLoading: true));
    try {
      final next = current.currentPage + 1;
      final newState = await _fetchPage(next, current.notifications);
      state = AsyncValue.data(newState);
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current == null) return;
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      
      if (id.startsWith('local_')) {
        if (userId.isNotEmpty) {
          await LocalNotificationStorage.markAsRead(userId, id);
        }
      } else {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.markAsRead(id);
      }
      
      final updated = current.notifications.map((n) {
        if (n.id == id) {
          return NotificationDto(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            readAt: DateTime.now().toIso8601String(),
            metadata: n.metadata,
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          );
        }
        return n;
      }).toList();
      state = AsyncValue.data(current.copyWith(notifications: updated));
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current == null) return;
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      
      if (userId.isNotEmpty) {
        await LocalNotificationStorage.markAllAsRead(userId);
      }
      
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
      
      final now = DateTime.now().toIso8601String();
      final updated = current.notifications.map((n) {
        if (!n.isRead) {
          return NotificationDto(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            readAt: now,
            metadata: n.metadata,
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          );
        }
        return n;
      }).toList();
      state = AsyncValue.data(current.copyWith(notifications: updated));
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    final current = state.value;
    if (current == null) return;
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      
      if (id.startsWith('local_')) {
        if (userId.isNotEmpty) {
          await LocalNotificationStorage.deleteNotification(userId, id);
        }
      } else {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.deleteNotification(id);
      }
      
      final updated = current.notifications.where((n) => n.id != id).toList();
      state = AsyncValue.data(current.copyWith(notifications: updated));
    } catch (_) {}
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
  () => NotificationNotifier(),
);

// Convenience provider for unread count (used in top app bar badge)
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifState = ref.watch(notificationNotifierProvider);
  return notifState.value?.unreadCount ?? 0;
});

// ---------------------------------------------------------------------------
// Preferences state
// ---------------------------------------------------------------------------

class PreferencesNotifier
    extends AsyncNotifier<NotificationPreferenceDto?> {
  NotificationPreferenceDto _fallbackPreferences() {
    return NotificationPreferenceDto(
      id: 'fallback_id',
      userId: 'fallback_user',
      emailEnabled: true,
      pushEnabled: true,
      weeklySummaryEnabled: false,
      dailyReminderEnabled: true,
    );
  }

  @override
  FutureOr<NotificationPreferenceDto?> build() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      return await repo.getPreferences();
    } catch (_) {
      return _fallbackPreferences();
    }
  }

  Future<void> updateSettings({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? weeklySummaryEnabled,
    bool? dailyReminderEnabled,
  }) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncValue.data(current.copyWith(
      emailEnabled: emailEnabled,
      pushEnabled: pushEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled,
      dailyReminderEnabled: dailyReminderEnabled,
    ));

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final updated = await repo.updatePreferences(
        emailEnabled: emailEnabled,
        pushEnabled: pushEnabled,
        weeklySummaryEnabled: weeklySummaryEnabled,
        dailyReminderEnabled: dailyReminderEnabled,
      );
      state = AsyncValue.data(updated);
    } catch (_) {
      // Revert on failure
      state = AsyncValue.data(current);
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, NotificationPreferenceDto?>(
  () => PreferencesNotifier(),
);
