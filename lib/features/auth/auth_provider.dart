

import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/data/datasource/remote/auth_api_service.dart';
import 'package:expense_management/features/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:expense_management/features/auth/domain/auth_notifier.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_management/features/auth/domain/use_case/login_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/register_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

//Khoi tao API = Dio
final authApiServiceProvider = Provider<AuthApiService>((ref){
  final dio = ref.watch(dioClientProvider);
  return AuthApiService(dio);
});

//Goi abstract repo de xu ly ben duoi bang impl
final authRepositoryProvider = Provider<AuthRepository>((ref){
  final apiService = ref.watch(authApiServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(apiService, secureStorage);
});

//useCase cho logic nghiep vu
final loginUseCaseProvider = Provider<LoginUseCase>((ref){
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginUseCase(authRepository);
});
final registerUseCaseProvider = Provider<RegisterUseCase>((ref){
  final authRepo = ref.watch(authRepositoryProvider);
  return RegisterUseCase(authRepo);
});

//Check state presentation -> UI
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref){
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final registerUseCase = ref.watch(registerUseCaseProvider);
  return AuthNotifier(loginUseCase,registerUseCase ,ref);
});

final splashCompletedProvider = StateProvider<bool>((ref) => false);

