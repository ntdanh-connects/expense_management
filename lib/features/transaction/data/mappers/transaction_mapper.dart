import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';

class TransactionMapper {
  static TransactionEntity toEntity(TransactionDto dto) {
    return TransactionEntity(
      id: dto.id,
      walletId: dto.walletId,
      categoryId: dto.categoryId,
      type: dto.type,
      status: dto.status,
      amount: dto.amount,
      currencyCode: dto.currencyCode,
      exchangeRate: dto.exchangeRate,
      title: dto.title,
      notes: dto.notes,
      timezone: dto.timezone,
      sourceType: dto.sourceType,
      transactionDate: dto.transactionDate,
      categoryName: dto.category?.name,
      categoryIcon: dto.category?.icon,
      categoryColor: dto.category?.color,
      walletName: dto.wallet?.name,
      walletIcon: dto.wallet?.icon,
      walletColor: dto.wallet?.color,
      attachmentUrls: dto.attachments?.map((a) => a.fileUrl).toList() ?? [],
    );
  }
}
