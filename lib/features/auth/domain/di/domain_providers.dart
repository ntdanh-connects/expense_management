import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/data/di/data_providers.dart';
import 'package:expense_management/features/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_management/features/auth/domain/use_case/confirm_link_social_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/login_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/register_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/social_login_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(apiService, secureStorage, localDataSource);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginUseCase(authRepository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return RegisterUseCase(authRepo);
});

final socialLoginUseCaseProvider = Provider<SocialLoginUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SocialLoginUseCase(authRepository);
});

final confirmLinkSocialUseCaseProvider = Provider<ConfirmLinkSocialUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ConfirmLinkSocialUseCase(authRepository);
});
