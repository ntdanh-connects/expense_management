import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionDateWalletRow extends ConsumerWidget {
  final DateTime selectedDate;
  final WalletEntity? selectedWallet;
  final List<WalletEntity> walletList;
  final VoidCallback onDateTap;
  final VoidCallback onWalletTap;
  final String Function(DateTime) formatDate;

  const TransactionDateWalletRow({
    super.key,
    required this.selectedDate,
    required this.selectedWallet,
    required this.walletList,
    required this.onDateTap,
    required this.onWalletTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Row(
      children: [
        // Date picker card
        Expanded(
          child: GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.authCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.textSecondary.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'date_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(selectedDate),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Wallet selector card
        Expanded(
          child: GestureDetector(
            onTap: onWalletTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.authCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.textSecondary.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'wallet_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedWallet?.name ?? 'select_wallet'.tr(ref),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
