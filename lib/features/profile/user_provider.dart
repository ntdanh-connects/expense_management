// import 'package:expense_management/features/auth/domain/auth_state.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:expense_management/core/network/dio_client.dart';
// import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
// import 'package:expense_management/features/auth/auth_provider.dart';

// // Khai báo các file mới thêm vào hệ thống Riverpod
// import 'package:expense_management/features/profile/data/datasource/remote/user_api_service.dart';
// import 'package:expense_management/features/profile/data/repository_impl/user_repository_impl.dart';
// import 'package:expense_management/features/profile/domain/repositories/user_repository.dart';
// import 'package:expense_management/features/profile/domain/use_case/update_profile_use_case.dart';

// // 1. Lắng nghe thông tin User hiện tại từ tầng Auth chung
// final currentUserProvider = Provider<UserEntity?>((ref) {
//   final authState = ref.watch(authNotifierProvider);
//   return authState.maybeWhen(
//     authenticated: (user) => user,
//     orElse: () => null,
//   );
// });

// // 2. Tạo UserApiService
// final userApiServiceProvider = Provider<UserApiService>((ref) {
//   final dio = ref.watch(dioClientProvider);
//   return UserApiService(dio);
// });

// // 3. Tạo UserRepository
// final userRepositoryProvider = Provider<UserRepository>((ref) {
//   final apiService = ref.watch(userApiServiceProvider);
//   return UserRepositoryImpl(apiService);
// });

// // 4. Tạo UpdateProfileUseCase
// final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
//   final repository = ref.watch(userRepositoryProvider);
//   return UpdateProfileUseCase(repository);
// });

import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/profile/data/repository_impl/user_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import 'package:expense_management/features/auth/auth_provider.dart';

import 'package:expense_management/features/profile/domain/repositories/user_repository.dart';
import 'package:expense_management/features/profile/domain/use_case/update_profile_use_case.dart';

/// Provider cung cấp thông tin người dùng hiện tại từ trạng thái đăng nhập chung.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Cấu hình dùng Mock UserRepository (Chưa cần API thực tế)
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepositoryImpl(ref);
});

/// Provider cung cấp UseCase cập nhật hồ sơ
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateProfileUseCase(repository);
});