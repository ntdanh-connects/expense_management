import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<List<TransactionEntity>> execute({
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
  }) {
    return _repository.getTransactions(
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
  }
}
