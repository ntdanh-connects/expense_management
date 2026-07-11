import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';

class QrTransferSenderCard extends ConsumerWidget {
  final List<WalletEntity> filteredWallets;
  final WalletEntity? selectedWallet;
  final ValueChanged<WalletEntity?> onWalletChanged;
  final bool isInternal;

  const QrTransferSenderCard({
    super.key,
    required this.filteredWallets,
    required this.selectedWallet,
    required this.onWalletChanged,
    required this.isInternal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.textSecondary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filteredWallets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                isInternal
                    ? 'qr_transfer_internal_no_wallet_warning'.tr(ref)
                    : 'qr_transfer_external_no_wallet_warning'.tr(ref),
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            )
          else
            DropdownButtonHideUnderline(
              child: DropdownButton<WalletEntity>(
                value: filteredWallets.contains(selectedWallet) ? selectedWallet : filteredWallets.first,
                dropdownColor: color.surface,
                items: filteredWallets.map((w) {
                  return DropdownMenuItem<WalletEntity>(
                    value: w,
                    child: Row(
                      children: [
                        Icon(
                          w.type == 'bank' ? Icons.account_balance_rounded : Icons.account_balance_wallet_rounded,
                          color: color.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${w.name} (${w.currencyCode})",
                          style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onWalletChanged,
              ),
            ),
          if (selectedWallet != null) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'available_balance'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontSize: 13),
                ),
                Text(
                  "${NumberFormat('#,###', 'vi_VN').format(selectedWallet!.balance)}đ",
                  style: TextStyle(color: color.incomeGreen, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
