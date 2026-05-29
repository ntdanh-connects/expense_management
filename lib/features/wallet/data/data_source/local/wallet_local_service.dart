import 'package:expense_management/core/database/app_database.dart';

class WalletLocalService {
  final AppDatabase _db;

  WalletLocalService(this._db);

  //Ghi đè cập nhật
  Future<void> cacheWallets(List<Wallet> walletRows) async {
    await _db.saveAllWallets(walletRows);
  }

  Future<void> createWallet(Wallet walletRow) async {
    await _db.createWallet(walletRow);
  }


  //Stream từ Drift DB lên
  Stream<List<Wallet>> watchCachedWallets() {
    return _db.watchAllWallets();
  }
}