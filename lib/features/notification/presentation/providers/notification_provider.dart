import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/dashboard/presentation/providers/recurring_provider.dart';
import 'package:expense_management/features/notification/domain/di/domain_providers.dart';
export 'package:expense_management/features/notification/domain/di/domain_providers.dart';
import 'package:expense_management/core/error/error_handler_mixin.dart';


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

class NotificationNotifier extends AsyncNotifier<NotificationState> with ErrorHandlerMixin {
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

    // Filter based on notification settings
    final pref = ref.read(notificationPreferencesProvider).value;
    final isPushEnabled = pref?.pushEnabled ?? true;
    final isBudgetEnabled = pref?.emailEnabled ?? true;
    final isDailyReminderEnabled = pref?.dailyReminderEnabled ?? true;

    final filtered = uniqueMerged.where((n) {
      if (n.type == 'recurring_created' || n.type == 'recurring') {
        return isPushEnabled;
      }
      if (n.type == 'budget_warning') {
        return isBudgetEnabled;
      }
      if (n.type == 'daily_reminder') {
        return isDailyReminderEnabled;
      }
      return true;
    }).toList();

    return NotificationState(
      notifications: filtered,
      isLoading: false,
      hasMore: remoteItems.length >= 15,
      currentPage: page,
    );
  }

  void addLocalNotification(NotificationDto notif) {
    final current = state.value;
    if (current == null) return;

    final pref = ref.read(notificationPreferencesProvider).value;
    final isPushEnabled = pref?.pushEnabled ?? true;
    final isBudgetEnabled = pref?.emailEnabled ?? true;
    final isDailyReminderEnabled = pref?.dailyReminderEnabled ?? true;

    if (notif.type == 'recurring_created' || notif.type == 'recurring') {
      if (!isPushEnabled) return;
    }
    if (notif.type == 'budget_warning') {
      if (!isBudgetEnabled) return;
    }
    if (notif.type == 'daily_reminder') {
      if (!isDailyReminderEnabled) return;
    }
    
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

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
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

  Future<void> deleteAllNotifications() async {
    final current = state.value;
    if (current == null) return;
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';

      // Xóa thông báo local
      if (userId.isNotEmpty) {
        await LocalNotificationStorage.clearAllNotifications(userId);
      }

      // Xóa thông báo remote (bỏ qua lỗi nếu không có kết nối)
      try {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.clearAllNotifications();
      } catch (_) {}

      state = AsyncValue.data(current.copyWith(notifications: []));
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
  static const String _prefKey = 'local_notification_preferences';

  Future<NotificationPreferenceDto> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return NotificationPreferenceDto.fromJson(jsonDecode(jsonStr));
      }
    } catch (_) {}
    return NotificationPreferenceDto(
      id: 'fallback_id',
      userId: 'fallback_user',
      emailEnabled: true,
      pushEnabled: true,
      weeklySummaryEnabled: false,
      dailyReminderEnabled: true,
    );
  }

  Future<void> _saveLocalPreferences(NotificationPreferenceDto dto) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(dto.toJson()));
    } catch (_) {}
  }

  @override
  FutureOr<NotificationPreferenceDto?> build() async {
    final local = await _loadLocalPreferences();
    // Set local preferences as initial state immediately
    state = AsyncValue.data(local);

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final remote = await repo.getPreferences();
      await _saveLocalPreferences(remote);
      return remote;
    } catch (_) {
      return local;
    }
  }

  Future<void> updateSettings({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? weeklySummaryEnabled,
    bool? dailyReminderEnabled,
  }) async {
    final current = state.value ?? await _loadLocalPreferences();

    final updated = current.copyWith(
      emailEnabled: emailEnabled,
      pushEnabled: pushEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled,
      dailyReminderEnabled: dailyReminderEnabled,
    );

    // Optimistic local update
    state = AsyncValue.data(updated);
    await _saveLocalPreferences(updated);

    // Trigger list filtering reactively
    ref.invalidate(notificationNotifierProvider);

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final remote = await repo.updatePreferences(
        emailEnabled: emailEnabled,
        pushEnabled: pushEnabled,
        weeklySummaryEnabled: weeklySummaryEnabled,
        dailyReminderEnabled: dailyReminderEnabled,
      );
      await _saveLocalPreferences(remote);
      state = AsyncValue.data(remote);
    } catch (_) {
      // Keep local update even if server fails
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, NotificationPreferenceDto?>(
  () => PreferencesNotifier(),
);

// Provider to store daily reminder time locally.
class DailyReminderTimeNotifier extends StateNotifier<TimeOfDay> {
  DailyReminderTimeNotifier() : super(const TimeOfDay(hour: 20, minute: 0)) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('daily_reminder_hour');
      final minute = prefs.getInt('daily_reminder_minute');
      if (hour != null && minute != null) {
        state = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
  }

  Future<void> setTime(TimeOfDay time) async {
    state = time;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_reminder_hour', time.hour);
      await prefs.setInt('daily_reminder_minute', time.minute);
    } catch (_) {}
  }
}

final dailyReminderTimeProvider =
    StateNotifierProvider<DailyReminderTimeNotifier, TimeOfDay>((ref) {
  return DailyReminderTimeNotifier();
});

// Listener/Manager for scheduling/cancelling notifications reactively
final notificationReminderManagerProvider = Provider<void>((ref) {
  final prefAsync = ref.watch(notificationPreferencesProvider);
  final time = ref.watch(dailyReminderTimeProvider);

  prefAsync.whenData((pref) {
    if (pref == null) return;

    // 1. Nhắc nhở ghi chép chi tiêu hàng ngày
    const dailyReminderId = 9999;
    if (pref.dailyReminderEnabled) {
      LocalNotificationService.scheduleDailyNotification(
        id: dailyReminderId,
        title: 'Nhắc nhở ghi chép chi tiêu',
        body: 'Đã đến giờ ghi chép chi tiêu rồi! Hãy ghi lại các giao dịch hôm nay nhé.',
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      LocalNotificationService.cancelNotification(dailyReminderId);
    }

    // 2. Nhắc nhở giao dịch định kỳ
    if (!pref.pushEnabled) {
      final rulesAsync = ref.read(recurringNotifierProvider);
      rulesAsync.whenData((rules) {
        for (final rule in rules) {
          LocalNotificationService.cancelNotification(rule.id.hashCode);
        }
      });
    } else {
      final rulesAsync = ref.read(recurringNotifierProvider);
      rulesAsync.whenData((rules) {
        ref.read(recurringNotifierProvider.notifier).refresh(silent: true);
      });
    }
  });
});

// Provider bật/tắt cảnh báo số dư tối thiểu — lưu local qua SharedPreferences
class MinimumBalanceAlertNotifier extends StateNotifier<bool> {
  MinimumBalanceAlertNotifier() : super(true) {
    _loadFromPrefs();
  }

  static const _key = 'minimum_balance_alert_enabled';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? true;
    } catch (_) {}
  }

  Future<void> toggle(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}

final minimumBalanceAlertProvider =
    StateNotifierProvider<MinimumBalanceAlertNotifier, bool>(
  (ref) => MinimumBalanceAlertNotifier(),
);
