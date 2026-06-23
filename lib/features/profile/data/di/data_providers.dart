import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/profile/data/datasource/remote/user_api_service.dart';
import 'package:expense_management/features/profile/data/datasource/remote/category_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return UserApiService(dio);
});

final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CategoryApiService(dio);
});
