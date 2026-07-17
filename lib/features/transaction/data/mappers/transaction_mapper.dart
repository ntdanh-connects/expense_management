import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class TransactionMapper {
  static TransactionEntity toEntity(TransactionDto dto) {
    final isSplit = dto.isSplit ?? false;
    final firstSplit = (isSplit && dto.splits != null && dto.splits!.isNotEmpty)
        ? dto.splits!.first
        : null;

    final fallbackWalletId = dto.walletId ?? firstSplit?.walletId;
    final fallbackAmount = dto.amount ?? (isSplit ? dto.amountInUserCurrency : null);

    String? fallbackWalletName = dto.wallet?.name;
    if (isSplit && dto.splits != null && dto.splits!.isNotEmpty) {
      fallbackWalletName = dto.splits!
          .map((s) => s.wallet?.name)
          .where((name) => name != null && name.isNotEmpty)
          .join(' + ');
      if (fallbackWalletName.isEmpty) {
        fallbackWalletName = 'Nhiều ví';
      }
    }

    final fallbackWalletIcon = dto.wallet?.icon ?? firstSplit?.wallet?.icon;
    final fallbackWalletColor = dto.wallet?.color ?? firstSplit?.wallet?.color;

    return TransactionEntity(
      id: dto.id,
      walletId: fallbackWalletId,
      categoryId: dto.categoryId,
      type: dto.type,
      status: dto.status,
      amount: fallbackAmount,
      currencyCode: dto.currencyCode,
      exchangeRate: dto.exchangeRate,
      amountInUserCurrency: dto.amountInUserCurrency,
      title: dto.title,
      notes: dto.notes,
      timezone: dto.timezone,
      sourceType: dto.sourceType,
      sourceId: dto.sourceId,
      transactionDate: AppConstant.adjustOldTransactionDate(dto.transactionDate, dto.timezone, dto.createdAt),
      createdAt: dto.createdAt,
      isSplit: isSplit,
      splits: dto.splits
          ?.map((s) => TransactionSplitEntity(
                id: s.id,
                walletId: s.walletId,
                amount: s.amount,
                amountInUserCurrency: s.amountInUserCurrency,
                walletName: s.wallet?.name,
                walletColor: s.wallet?.color,
                walletIcon: s.wallet?.icon,
              ))
          .toList(),
      categoryName: dto.category?.name,
      categoryIcon: dto.category?.icon,
      categoryColor: dto.category?.color,
      walletName: fallbackWalletName,
      walletIcon: fallbackWalletIcon,
      walletColor: fallbackWalletColor,
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
