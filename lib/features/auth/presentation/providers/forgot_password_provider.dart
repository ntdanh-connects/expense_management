import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final forgotPasswordProvider = StateNotifierProvider<ForgotPasswordNotifier, AsyncValue<void>>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return ForgotPasswordNotifier(authRepository);
});

class ForgotPasswordNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  ForgotPasswordNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> sendResetLink(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.forgotPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}