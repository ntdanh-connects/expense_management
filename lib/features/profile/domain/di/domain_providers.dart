import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/profile/data/di/data_providers.dart';
import 'package:expense_management/features/profile/data/repository_impl/user_repository_impl.dart';
import 'package:expense_management/features/profile/data/repository_impl/category_repository_impl.dart';
import 'package:expense_management/features/profile/domain/repositories/user_repository.dart';
import 'package:expense_management/features/profile/domain/repositories/category_repository.dart';
import 'package:expense_management/features/profile/domain/use_case/update_profile_use_case.dart';
import 'package:expense_management/features/profile/domain/use_case/update_avatar_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(userApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return UserRepositoryImpl(apiService, db, secureStorage);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiService = ref.watch(categoryApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryImpl(apiService, db);
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

final updateAvatarUseCaseProvider = Provider<UpdateAvatarUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateAvatarUseCase(repository);
});
