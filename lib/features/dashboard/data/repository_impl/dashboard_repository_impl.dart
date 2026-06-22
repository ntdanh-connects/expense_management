import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/dashboard/data/datasource/remote/dashboard_api_service.dart';
import 'package:expense_management/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:expense_management/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:expense_management/features/wallet/data/data_source/local/wallet_local_service.dart';
import 'package:expense_management/features/wallet/data/mapper/wallet_mapper.dart';
import 'package:expense_management/features/transaction/data/mappers/transaction_mapper.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardApiService _apiService;
  final WalletLocalService _walletLocalDataSource;
  final AppDatabase _database;
  final String Function() _getUserId;

  DashboardRepositoryImpl(
    this._apiService,
    this._walletLocalDataSource,
    this._database,
    this._getUserId,
  );

  @override
  Future<DashboardSummaryDto> getSummary() async {
    try {
      final response = await _apiService.getDashboardSummary();
      final summaryDto = response.data;

      final userId = _getUserId();
      if (userId.isNotEmpty) {
        // 1. Đồng bộ Wallets vào SQLite local
        final walletDbRows = summaryDto.wallets
            .map((dto) => WalletMapper.toDatabaseRow(dto))
            .toList();
        await _walletLocalDataSource.cacheWallets(walletDbRows);
        AppLogger.debug("💾 [DashboardRepo] Đã đồng bộ ${walletDbRows.length} ví vào SQLite local từ Dashboard Summary", tag: "SQLite");

        // 2. Đồng bộ Recent Transactions vào SQLite local
        final transactionEntities = summaryDto.recentTransactions
            .map((dto) => TransactionMapper.toEntity(dto))
            .toList();
        final localTxs = transactionEntities.map((tx) {
          return LocalTransaction(
            id: tx.id,
            userId: userId,
            walletId: tx.walletId,
            categoryId: tx.categoryId,
            amount: tx.amount,
            amountInUserCurrency: tx.amount * (tx.exchangeRate ?? 1.0),
            type: tx.type,
            title: tx.title,
            notes: tx.notes,
            transactionDate: tx.transactionDate,
            sourceType: tx.sourceType,
            sourceId: tx.sourceId,
            createdAt: tx.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: true,
            payeeId: tx.payeeId,
            payeeName: tx.payeeName,
            payeeAccountNumber: tx.payeeAccountNumber,
            payeeBankName: tx.payeeBankName,
            isTransferLocked: tx.isTransferLocked,
          );
        }).toList();

        await _database.saveAllTransactions(localTxs).catchError((err) {
          AppLogger.error('🚨 [DashboardRepo] Lỗi lưu cache Transactions vào Drift SQLite: $err', tag: 'DashboardRepo');
        });
        AppLogger.debug("💾 [DashboardRepo] Đã đồng bộ ${localTxs.length} giao dịch vào SQLite local từ Dashboard Summary", tag: "SQLite");
      }

      return summaryDto;
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [DashboardRepo] Lỗi getSummary: $e", tag: "Dashboard", stackTrace: stackTrace);
      rethrow;
    }
  }
}
