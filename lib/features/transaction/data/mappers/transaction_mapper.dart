import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/core/constants/app_constant.dart';

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
      transactionDate: AppConstant.adjustOldTransactionDate(dto.transactionDate, dto.timezone, dto.createdAt),
      createdAt: dto.createdAt,
      categoryName: dto.category?.name,
      categoryIcon: dto.category?.icon,
      categoryColor: dto.category?.color,
      walletName: dto.wallet?.name,
      walletIcon: dto.wallet?.icon,
      walletColor: dto.wallet?.color,
      attachmentUrls: dto.attachments?.map((a) => a.fileUrl).toList() ?? [],
      isTransferLocked: dto.isTransferLocked ?? false,
      payeeId: dto.payeeId ?? dto.payee?.id,
      payeeName: dto.payee?.payeeName,
      payeeAccountNumber: dto.payee?.identifier,
      payeeBankName: dto.payee?.bankName,
      senderName: dto.sender?.name,
      senderWalletName: dto.sender?.walletName,
      senderIdentifier: dto.sender?.identifier,
    );
  }
}
