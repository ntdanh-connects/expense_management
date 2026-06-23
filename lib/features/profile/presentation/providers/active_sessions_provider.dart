import 'dart:async';
import 'package:expense_management/features/profile/data/models/user_session_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeSessionsProvider = AsyncNotifierProvider.autoDispose<ActiveSessionsNotifier, List<UserSessionDto>>(() {
  return ActiveSessionsNotifier();
});

class ActiveSessionsNotifier extends AsyncNotifier<List<UserSessionDto>> {
  @override
  FutureOr<List<UserSessionDto>> build() {
    // Tự động lắng nghe trạng thái Auth, nếu đổi tài khoản sẽ tự động rebuild/fetch lại fresh data
    ref.watch(authNotifierProvider.select((state) => state.maybeWhen(authenticated: (u) => u.id, orElse: () => null)));
    return ref.read(userRepositoryProvider).getActiveSessions();
  }

  Future<void> refreshSessions({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).getActiveSessions());
  }

  Future<void> revokeSession(String sessionId, {bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      await ref.read(userRepositoryProvider).revokeSession(sessionId);
      state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).getActiveSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> revokeAllSessions({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      await ref.read(userRepositoryProvider).logoutAllDevices();
      state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).getActiveSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
