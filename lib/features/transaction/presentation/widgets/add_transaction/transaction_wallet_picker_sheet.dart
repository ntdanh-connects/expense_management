import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionWalletPickerSheet extends ConsumerWidget {
  final List<WalletEntity> wallets;
  final WalletEntity? selectedWallet;
  final ValueChanged<WalletEntity> onSelected;

  const TransactionWalletPickerSheet({
    super.key,
    required this.wallets,
    required this.selectedWallet,
    required this.onSelected,
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'select_transaction_wallet'.tr(ref),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (wallets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'manual_transaction_wallet_warning'.tr(ref),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: wallets.length,
                itemBuilder: (context, idx) {
                  final wallet = wallets[idx];
                  final hexColor = wallet.color.replaceAll('#', '');
                  Color itemColor;
                  try {
                    itemColor = hexColor.length == 6
                        ? Color(int.parse('FF$hexColor', radix: 16))
                        : colors.primary;
                  } catch (_) {
                    itemColor = colors.primary;
                  }

                  final isSelected = selectedWallet?.id == wallet.id;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        wallet.type.toLowerCase() == 'cash'
                            ? Icons.payments_rounded
                            : wallet.type.toLowerCase() == 'bank'
                            ? Icons.account_balance_rounded
                            : Icons.credit_card_rounded,
                        color: itemColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      wallet.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${'balance_prefix'.tr(ref)}${NumberFormat(wallet.currencyCode == 'VND' ? '#,###' : '#,##0.00').format(wallet.balance)} ${_getCurrencySymbol(wallet.currencyCode)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () => onSelected(wallet),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'close_label'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
