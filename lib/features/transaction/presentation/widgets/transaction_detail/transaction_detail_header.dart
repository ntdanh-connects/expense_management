import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class TransactionDetailHeader extends ConsumerWidget {
  final TransactionEntity transaction;
  final String localeCode;

  const TransactionDetailHeader({
    super.key,
    required this.transaction,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currencySymbol = transaction.currencyCode ?? 'đ';
    final formattedAmount =
        AppConstant.formatMoney(transaction.amount, transaction.currencyCode);
    final sign = transaction.type == 'income'
        ? '+'
        : (transaction.type == 'expense' ? '-' : '');
    final amountColor = transaction.type == 'income'
        ? colors.incomeGreen
        : (transaction.type == 'expense' ? colors.expenseRed : colors.textSecondary);

    return Center(
      child: Column(
        children: [
          Text(
            '$sign$formattedAmount $currencySymbol',
            style: TextStyle(
              color: amountColor,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (transaction.currencyCode == 'VND' ||
              transaction.currencyCode == null) ...[
            const SizedBox(height: 4),
            Text(
              '(${formatNumberToWords(transaction.amount, localeCode)})',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'wallet_with_name'
                  .tr(ref)
                  .replaceAll('{name}', transaction.walletName ?? 'default_label'.tr(ref)),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
