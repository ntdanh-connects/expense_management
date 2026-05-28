import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/profile/data/datasource/remote/user_api_service.dart';
import 'package:expense_management/features/profile/data/repository_impl/user_repository_impl.dart';
import 'package:expense_management/features/profile/domain/repositories/user_repository.dart';
import 'package:expense_management/features/profile/domain/use_case/update_profile_use_case.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider cung cấp thông tin người dùng hiện tại từ trạng thái đăng nhập chung.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Tạo UserApiService
final userApiServiceProvider = Provider<UserApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return UserApiService(dio);
});

/// Cấu hình dùng UserRepository với đồng bộ SQLite và Remote API
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(userApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return UserRepositoryImpl(apiService, db, secureStorage);
});

/// Provider cung cấp UseCase cập nhật hồ sơ
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateProfileUseCase(repository);
});