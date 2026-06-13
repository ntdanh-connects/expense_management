import 'package:dio/dio.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository _repository;

  AddTransactionUseCase(this._repository);

  Future<TransactionEntity> execute({
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
    String? payeeId,
  }) {
    return _repository.createTransaction(
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
      payeeId: payeeId,
    );
  }
}
