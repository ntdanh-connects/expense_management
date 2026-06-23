import 'package:expense_management/features/auth/domain/auth_notifier.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/domain/di/domain_providers.dart';
import 'package:flutter_riverpod/legacy.dart';

export 'package:expense_management/features/auth/domain/di/domain_providers.dart';
export 'package:expense_management/features/auth/domain/auth_state.dart';
export 'package:expense_management/features/auth/domain/auth_notifier.dart';

// Presentation State Notification Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final registerUseCase = ref.watch(registerUseCaseProvider);
  final socialLoginUseCase = ref.watch(socialLoginUseCaseProvider);
  final confirmLinkSocialUseCase = ref.watch(confirmLinkSocialUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(
    loginUseCase,
    registerUseCase,
    socialLoginUseCase,
    confirmLinkSocialUseCase,
    authRepository,
    ref,
  );
});

final splashCompletedProvider = StateProvider<bool>((ref) => false);

final sessionExpiredProvider = StateProvider<bool>((ref) => false);
