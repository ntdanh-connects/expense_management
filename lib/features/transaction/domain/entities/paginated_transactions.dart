import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';

class PaginatedTransactions {
  final List<TransactionEntity> items;
  final String? nextCursor;

  PaginatedTransactions({
    required this.items,
    this.nextCursor,
  });
}
