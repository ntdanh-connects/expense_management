import 'package:dio/dio.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/entities/paginated_transactions.dart';

abstract class TransactionRepository {
  Future<PaginatedTransactions> getTransactions({
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
    String? cursor,
  });

  Future<TransactionEntity> createTransaction({
    String? id,
    String? walletId,
    String? categoryId,
    required String type,
    double? amount,
    required String title,
    String? notes,
    String? transactionDate,
    String? currencyCode,
    double? exchangeRate,
    String? timezone,
    MultipartFile? attachment,
    String? payeeId,
    String? sourceType,
    List<Map<String, dynamic>>? splits,
  });

  Future<TransactionEntity> getTransactionById(String id);

  Future<TransactionEntity> updateTransaction({
    required String id,
    required String title,
    String? categoryId,
    String? notes,
    String? payeeId,
    String? sourceType,
    String? type,
    MultipartFile? attachment,
    double? amount,
    String? walletId,
    List<Map<String, dynamic>>? splits,
  });

  Future<void> deleteTransaction(String id);
}
