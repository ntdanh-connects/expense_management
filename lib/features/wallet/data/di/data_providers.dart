import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/wallet/data/data_source/local/wallet_local_service.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/wallet_api_service.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/qr_transfer_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletApiServiceProvider = Provider<WalletApiService>((ref) {
  final dio = ref.read(dioClientProvider); 
  return WalletApiService(dio);
});

final walletLocalDataSourceProvider = Provider<WalletLocalService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return WalletLocalService(db);
});

final qrTransferApiServiceProvider = Provider<QrTransferApiService>((ref) {
  final dio = ref.read(dioClientProvider);
  return QrTransferApiService(dio);
});
