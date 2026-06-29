import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionHistoryWalletPickerSheet extends ConsumerWidget {
  final AsyncValue<List<WalletEntity>> walletState;
  final String? walletId;
  final VoidCallback onClear;
  final ValueChanged<WalletEntity> onSelected;

  const TransactionHistoryWalletPickerSheet({
    super.key,
    required this.walletState,
    required this.walletId,
    required this.onClear,
    required this.onSelected,
  });

  IconData _getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e-wallet':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  Widget _buildPickerShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return walletState.when(
      data: (allWallets) {
        final wallets = allWallets.where((w) => !w.isHidden).toList();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'filter_by_wallet'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (walletId != null)
                      TextButton(
                        onPressed: onClear,
                        child: Text(
                          'clear'.tr(ref),
                          style: TextStyle(color: colors.expenseRed),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: walletId == null ? colors.primary : colors.textSecondary,
                      ),
                      title: Text(
                        'all_wallets'.tr(ref),
                        style: TextStyle(
                          color: walletId == null ? colors.primary : colors.textPrimary,
                          fontWeight: walletId == null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: walletId == null
                          ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                          : null,
                      onTap: onClear,
                    ),
                    ...wallets.map((w) {
                      final isSelected = walletId == w.id;
                      return ListTile(
                        leading: Icon(
                          _getWalletIcon(w.type),
                          color: isSelected ? colors.primary : colors.textSecondary,
                        ),
                        title: Text(
                          w.name,
                          style: TextStyle(
                            color: isSelected ? colors.primary : colors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                            : null,
                        onTap: () => onSelected(w),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildPickerShimmer(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
      error: (err, _) => Center(child: Text('load_transactions_error'.tr(ref))),
    );
  }
}
