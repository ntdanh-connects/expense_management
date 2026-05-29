import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/wallet/data/data_source/local/wallet_local_service.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/wallet_api_service.dart';
import 'package:expense_management/features/wallet/data/mapper/wallet_mapper.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/core/database/app_database.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletRepositoryImpl  implements WalletRepository{
  final WalletApiService _apiService;
  final WalletLocalService _localDataSource;
  final SecureStorageService _secureStorage;

  WalletRepositoryImpl(this._apiService, this._localDataSource, this._secureStorage);

  @override
  Future<void> syncWalletsImplicit() async {
    try {
      final userId = await _secureStorage.get(key: AppConstant.userId);
      if (userId == null) {
        throw Exception("User ID not found in secure storage.");
      }

      final response = await _apiService.getRemoteWallets(userId);
    
      final dtoList = response.data;

      final dbRows = dtoList.map((dto) => WalletMapper.toDatabaseRow(dto)).toList();

      await _localDataSource.cacheWallets(dbRows);
    } catch (e, stackTrace) {
      print('Error syncing wallets: $e');
      print(stackTrace);
    }
  }

  @override
  Stream<List<WalletEntity>> watchWallets() {
    return _localDataSource.watchCachedWallets().map((rows) {
      return rows.map((row) => WalletMapper.toEntity(row)).toList();
    });
  }

  @override
  Future<void> createWallet(WalletEntity wallet) async {
    final row = Wallet(
      id: wallet.id,
      name: wallet.name,
      balance: wallet.balance,
      type: wallet.type,
      icon: wallet.icon,
      color: wallet.color,
      isHidden: false,
    );
    await _localDataSource.createWallet(row);
  }
}