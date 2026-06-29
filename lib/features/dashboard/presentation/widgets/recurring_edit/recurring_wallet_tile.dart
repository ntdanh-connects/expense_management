import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';

class RecurringWalletTile extends ConsumerWidget {
  final WalletEntity? selectedWallet;
  final VoidCallback onTap;

  const RecurringWalletTile({
    super.key,
    required this.selectedWallet,
    required this.onTap,
  });

  String _getCurrencySymbol(String? code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return 'đ';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: selectedWallet == null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(Icons.account_balance_wallet_rounded,
                        color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('recurring_select_wallet'.tr(ref),
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 15))),
                  Icon(Icons.chevron_right_rounded,
                      color: colors.textSecondary.withOpacity(0.5)),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(
                      selectedWallet!.type.toLowerCase() == 'bank'
                          ? Icons.account_balance_rounded
                          : selectedWallet!.type.toLowerCase() == 'e-wallet'
                              ? Icons.qr_code_scanner_rounded
                              : Icons.payments_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedWallet!.name,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(
                          '${AppConstant.formatMoney(selectedWallet!.balance, selectedWallet!.currencyCode)} ${_getCurrencySymbol(selectedWallet!.currencyCode)}',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text('recurring_change'.tr(ref),
                      style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
