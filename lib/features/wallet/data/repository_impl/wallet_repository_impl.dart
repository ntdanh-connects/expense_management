import 'package:dio/dio.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/wallet/data/data_source/local/wallet_local_service.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/wallet_api_service.dart';
import 'package:expense_management/features/wallet/data/mapper/wallet_mapper.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletRepositoryImpl  implements WalletRepository{
  final WalletApiService _apiService;
  final WalletLocalService _localDataSource;
  final SecureStorageService _secureStorage;

  WalletRepositoryImpl(this._apiService, this._localDataSource, this._secureStorage);

  @override
  Future<void> syncWalletsImplicit() async {
    try {
      final response = await _apiService.getRemoteWallets();
    
      final dtoList = response.data;

      final dbRows = dtoList.map((dto) => WalletMapper.toDatabaseRow(dto)).toList();

      await _localDataSource.cacheWallets(dbRows);

      AppLogger.debug("💾 [SQLite] Đã đồng bộ ngầm ${dbRows.length} ví từ remote BE vào SQLite local", tag: "SQLite");
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SQLite] Lỗi đồng bộ ngầm ví: $e", tag: "SQLite", stackTrace: stackTrace);
    }
  }

  @override
  Stream<List<WalletEntity>> watchWallets() {
    return _localDataSource.watchCachedWallets().map((rows) {
      return rows.map((row) => WalletMapper.toEntity(row)).toList();
    });
  }

  @override
  Future<void> createWallet(CreateWalletRequest request) async {
    AppLogger.debug("🌐 [Wallet-Sync] Bắt đầu gửi yêu cầu tạo ví mới '${request.name}' lên Remote Server...", tag: "Wallet-Sync");
    try {
      final response = await _apiService.createRemoteWallet(request);
      final walletDto = response.data;
      AppLogger.info("☁️ [Wallet-Sync] Tạo ví mới '${request.name}' trên Remote Server thành công! Tiến hành lưu vào SQLite...", tag: "Wallet-Sync");

      final row = WalletMapper.toDatabaseRow(walletDto);
      await _localDataSource.createWallet(row);

      AppLogger.info("💾 [SQLite] Đã lưu ví mới '${row.name}' vào SQLite local thành công!", tag: "SQLite");
    } catch (e, stackTrace) {
      if (e is DioException) {
        final serverError = e.response?.data;
        AppLogger.error("🚨 [Wallet-Sync] Lỗi tạo ví trên Remote Server: ${e.message}. Chi tiết từ Server: $serverError", tag: "Wallet-Sync", stackTrace: stackTrace);
      } else {
        AppLogger.error("🚨 [SQLite] Lỗi lưu ví mới vào SQLite local: $e", tag: "SQLite", stackTrace: stackTrace);
      }
      rethrow; 
    }
  }

  @override
  Future<void> updateWallet(String id, CreateWalletRequest request) async {
    AppLogger.debug("🌐 [Wallet-Sync] Bắt đầu gửi yêu cầu cập nhật ví ID: $id (Tên mới: '${request.name}') lên Remote Server...", tag: "Wallet-Sync");
    try {
      final response = await _apiService.updateRemoteWallet(id, request);
      final walletDto = response.data;
      AppLogger.info("☁️ [Wallet-Sync] Cập nhật ví ID: $id trên Remote Server thành công! Tiến hành ghi đè SQLite local...", tag: "Wallet-Sync");

      final row = WalletMapper.toDatabaseRow(walletDto);
      await _localDataSource.createWallet(row); // Drift insertOnConflictUpdate tự động ghi đè bản ghi cũ trùng ID

      AppLogger.info("💾 [SQLite] Cập nhật ví '${row.name}' (ID: $id) vào SQLite local thành công!", tag: "SQLite");
    } catch (e, stackTrace) {
      if (e is DioException) {
        final serverError = e.response?.data;
        AppLogger.error("🚨 [Wallet-Sync] Lỗi cập nhật ví trên Remote Server: ${e.message}. Chi tiết từ Server: $serverError", tag: "Wallet-Sync", stackTrace: stackTrace);
      } else {
        AppLogger.error("🚨 [SQLite] Lỗi cập nhật ví trong SQLite local: $e", tag: "SQLite", stackTrace: stackTrace);
      }
      rethrow;
    }
  }
}