import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/wallet/data/di/data_providers.dart';
import 'package:expense_management/features/wallet/data/repository_impl/wallet_repository_impl.dart';
import 'package:expense_management/features/wallet/data/repository_impl/qr_transfer_repository_impl.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/features/wallet/domain/repository/qr_transfer_repository.dart';
import 'package:expense_management/features/wallet/domain/use_case/create_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/get_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/sync_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/update_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/set_default_receiving_wallet_use_case.dart';
import 'package:expense_management/features/wallet/domain/use_case/simulate_sandbox_transfer_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiService = ref.read(walletApiServiceProvider);
  final localDataSource = ref.read(walletLocalDataSourceProvider);
  final secureStorage = ref.read(secureStorageServiceProvider);
  final cacheStore = ref.read(cacheStoreProvider);
  return WalletRepositoryImpl(
    apiService,
    localDataSource,
    secureStorage,
    cleanCache: () => cacheStore.clean(),
  );
});

final qrTransferRepositoryProvider = Provider<QrTransferRepository>((ref) {
  final apiService = ref.watch(qrTransferApiServiceProvider);
  return QrTransferRepositoryImpl(apiService);
});

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

final setDefaultReceivingWalletUseCaseProvider = Provider<SetDefaultReceivingWalletUseCase>((ref) {
  final repository = ref.read(walletRepositoryProvider);
  return SetDefaultReceivingWalletUseCase(repository);
});

final simulateSandboxTransferUseCaseProvider = Provider<SimulateSandboxTransferUseCase>((ref) {
  final repository = ref.read(walletRepositoryProvider);
  return SimulateSandboxTransferUseCase(repository);
});
