import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/auth/data/datasource/local/auth_local_data_source.dart';
import 'package:expense_management/features/auth/data/datasource/remote/auth_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthApiService(dio);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuthLocalDataSource(db);
});
