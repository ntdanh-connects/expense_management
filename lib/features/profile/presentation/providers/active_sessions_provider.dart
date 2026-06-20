import 'dart:async';
import 'package:expense_management/features/profile/data/models/user_session_dto.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
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

  Future<void> refreshSessions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).getActiveSessions());
  }

  Future<void> revokeSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(userRepositoryProvider).revokeSession(sessionId);
      state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).getActiveSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> revokeAllSessions() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(userRepositoryProvider).logoutAllDevices();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
