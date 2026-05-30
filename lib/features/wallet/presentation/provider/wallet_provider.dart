import 'package:expense_management/features/wallet/data/data_source/local/wallet_local_service.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/wallet_api_service.dart';
import 'package:expense_management/features/wallet/data/repository_impl/wallet_repository_impl.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/features/wallet/domain/use_case/create_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/get_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/sync_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/update_wallet_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';

// API Service
final walletApiServiceProvider = Provider<WalletApiService>((ref) {
  final dio = ref.read(dioClientProvider); 
  return WalletApiService(dio);
});

//Local
final walletLocalDataSourceProvider = Provider<WalletLocalService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return WalletLocalService(db);
});

// RepoInterface
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiService = ref.read(walletApiServiceProvider);
  final localDataSource = ref.read(walletLocalDataSourceProvider);
  final secureStorage = ref.read(secureStorageServiceProvider);
  return WalletRepositoryImpl(apiService, localDataSource, secureStorage);
});


//Use Case
final watchWalletsUseCaseProvider = Provider<GetWalletUseCase>((ref) {
  final repository = ref.read(walletRepositoryProvider);
  return GetWalletUseCase(repository);
});

final syncWalletsUseCaseProvider = Provider<SyncWalletsUseCase>((ref) {
  final repository = ref.read(walletRepositoryProvider);
  return SyncWalletsUseCase(repository);
});

final createWalletUseCaseProvider = Provider<CreateWalletUseCase>((ref) {
  final repository = ref.read(walletRepositoryProvider);
  return CreateWalletUseCase(repository);
});

final updateWalletUseCaseProvider = Provider<UpdateWalletUseCase>((ref) {
  final repository = ref.read(walletRepositoryProvider);
  return UpdateWalletUseCase(repository);
});