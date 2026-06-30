import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';

class SandboxWalletSelector extends StatelessWidget {
  final WalletEntity? selectedWallet;
  final List<WalletEntity> wallets;
  final ValueChanged<WalletEntity?> onChanged;

  const SandboxWalletSelector({
    super.key,
    required this.selectedWallet,
    required this.wallets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ví thụ hưởng'.toUpperCase(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.textSecondary.withOpacity(0.15),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<WalletEntity>(
              value: selectedWallet,
              isExpanded: true,
              dropdownColor: colors.surface,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              items: wallets.map((wallet) {
                return DropdownMenuItem<WalletEntity>(
                  value: wallet,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                              wallet.color.replaceAll('#', 'FF'),
                              radix: 16,
                            ),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${wallet.name} (${AppConstant.formatMoney(wallet.balance, wallet.currencyCode)} đ)',
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
