import 'package:dio/dio.dart';
import 'package:expense_management/features/transaction/data/datasource/remote/transaction_remote_datasource.dart';
import 'package:expense_management/features/transaction/data/mappers/transaction_mapper.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/core/utils/app_logger.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionApiService _apiService;

  TransactionRepositoryImpl(this._apiService);

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? search,
    String? startDate,
    String? endDate,
    String? categoryId,
    String? type,
    double? minAmount,
    double? maxAmount,
    String? walletId,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) async {
    try {
      final response = await _apiService.getRemoteTransactions(
        search: search,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        type: type,
        minAmount: minAmount,
        maxAmount: maxAmount,
        walletId: walletId,
        sortBy: sortBy,
        sortOrder: sortOrder,
        perPage: perPage,
      );
      final dtoList = response.data ?? [];
      return dtoList.map((dto) => TransactionMapper.toEntity(dto)).toList();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [TransactionRepo] Error getting remote transactions: $e", tag: "TransactionRepo", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<TransactionEntity> createTransaction({
    required String walletId,
    String? categoryId,
    required String type,
    required double amount,
    required String title,
    String? notes,
    String? transactionDate,
    String? currencyCode,
    double? exchangeRate,
    String? timezone,
    MultipartFile? attachment,
  }) async {
    try {
      final response = await _apiService.createRemoteTransaction(
        walletId: walletId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        title: title,
        notes: notes,
        transactionDate: transactionDate,
        currencyCode: currencyCode,
        exchangeRate: exchangeRate,
        timezone: timezone,
        attachment: attachment,
      );
      return TransactionMapper.toEntity(response.data);
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [TransactionRepo] Error creating transaction: $e", tag: "TransactionRepo", stackTrace: stackTrace);
      rethrow;
    }
  }
}
