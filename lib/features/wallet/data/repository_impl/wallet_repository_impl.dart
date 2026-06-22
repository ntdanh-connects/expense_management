import 'package:dio/dio.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/wallet/data/data_source/local/wallet_local_service.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/wallet_api_service.dart';
import 'package:expense_management/features/wallet/data/mapper/wallet_mapper.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/internal_transfer_record.dart';

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

  @override
  Future<void> transferMoney({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? notes,
    String? timezone,
  }) async {
    AppLogger.debug("🌐 [Wallet-Sync] Bắt đầu gửi yêu cầu chuyển tiền từ ví $fromWalletId sang ví $toWalletId...", tag: "Wallet-Sync");
    try {
      final body = {
        'from_wallet_id': fromWalletId,
        'to_wallet_id': toWalletId,
        'amount': amount,
        if (notes != null) 'notes': notes,
        if (timezone != null) 'timezone': timezone,
      };
      await _apiService.transferMoney(body);
      AppLogger.info("☁️ [Wallet-Sync] Chuyển tiền thành công trên Remote Server! Tiến hành đồng bộ lại ví...", tag: "Wallet-Sync");
      
      // Đồng bộ lại danh sách ví để cập nhật số dư mới nhất vào SQLite
      await syncWalletsImplicit();
    } catch (e, stackTrace) {
      if (e is DioException) {
        final serverError = e.response?.data;
        AppLogger.error("🚨 [Wallet-Sync] Lỗi chuyển tiền trên Remote Server: ${e.message}. Chi tiết từ Server: $serverError", tag: "Wallet-Sync", stackTrace: stackTrace);
      } else {
        AppLogger.error("🚨 [Wallet-Sync] Lỗi chuyển tiền cục bộ: $e", tag: "Wallet-Sync", stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  @override
  Future<List<InternalTransferRecord>> getTransferHistory() async {
    AppLogger.debug("🌐 [Wallet-Sync] Bắt đầu lấy lịch sử chuyển tiền từ Remote Server...", tag: "Wallet-Sync");
    try {
      final response = await _apiService.getTransfers();
      final List<dynamic> list = response.data ?? [];
      
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return InternalTransferRecord(
          id: map['id']?.toString() ?? '',
          fromWalletName: map['from_wallet_name']?.toString() ?? '',
          toWalletName: map['to_wallet_name']?.toString() ?? '',
          amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
          date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
          timezone: map['timezone']?.toString(),
          currencyCode: map['currency_code']?.toString(),
        );
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [Wallet-Sync] Lỗi lấy lịch sử chuyển tiền: $e", tag: "Wallet-Sync", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setDefaultReceivingWallet(String id) async {
    AppLogger.debug("🌐 [Wallet-Sync] Bắt đầu gửi yêu cầu đặt ví mặc định nhận tiền ID: $id lên Remote Server...", tag: "Wallet-Sync");
    try {
      await _apiService.setDefaultReceivingWallet(id);
      AppLogger.info("☁️ [Wallet-Sync] Đặt ví mặc định nhận tiền ID: $id trên Remote Server thành công! Đồng bộ lại ví...", tag: "Wallet-Sync");
      await syncWalletsImplicit();
    } catch (e, stackTrace) {
      if (e is DioException) {
        final serverError = e.response?.data;
        AppLogger.error("🚨 [Wallet-Sync] Lỗi đặt ví mặc định nhận tiền trên Remote Server: ${e.message}. Chi tiết từ Server: $serverError", tag: "Wallet-Sync", stackTrace: stackTrace);
      } else {
        AppLogger.error("🚨 [Wallet-Sync] Lỗi đặt ví mặc định nhận tiền cục bộ: $e", tag: "Wallet-Sync", stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  @override
  Future<String?> simulateSandboxTransfer({
    required String walletId,
    required double amount,
    String? senderName,
    String? notes,
  }) async {
    AppLogger.debug("🌐 [Wallet-Sync] Bắt đầu gửi yêu cầu giả lập nhận tiền từ Sandbox...", tag: "Wallet-Sync");
    try {
      final body = {
        'wallet_id': walletId,
        'amount': amount,
        if (senderName != null) 'sender_name': senderName,
        if (notes != null) 'notes': notes,
      };
      final response = await _apiService.simulateSandboxTransfer(body);
      AppLogger.info("☁️ [Wallet-Sync] Giả lập nhận tiền thành công trên Remote Server! Tiến hành đồng bộ lại ví...", tag: "Wallet-Sync");
      await syncWalletsImplicit();

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final tx = data['transaction'];
        if (tx is Map<String, dynamic>) {
          return tx['id']?.toString();
        }
      }
      return null;
    } catch (e, stackTrace) {
      if (e is DioException) {
        final serverError = e.response?.data;
        AppLogger.error("🚨 [Wallet-Sync] Lỗi giả lập nhận tiền trên Remote Server: ${e.message}. Chi tiết từ Server: $serverError", tag: "Wallet-Sync", stackTrace: stackTrace);
      } else {
        AppLogger.error("🚨 [Wallet-Sync] Lỗi giả lập nhận tiền cục bộ: $e", tag: "Wallet-Sync", stackTrace: stackTrace);
      }
      rethrow;
    }
  }
}