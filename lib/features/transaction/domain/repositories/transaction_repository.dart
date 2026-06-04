import 'package:dio/dio.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
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
  });

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
  });
}
