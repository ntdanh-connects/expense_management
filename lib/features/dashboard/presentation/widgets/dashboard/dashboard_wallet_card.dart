import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_balance_card.dart'; // import showBalanceProvider

class DashboardWalletList extends ConsumerWidget {
  const DashboardWalletList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final walletState = ref.watch(walletNotifierProvider);
    final showBalance = ref.watch(showBalanceProvider);

    return SizedBox(
      height: 125,
      child: walletState.when(
        data: (walletList) {
          final visibleWallets = walletList.where((w) => !w.isHidden).toList();
          if (visibleWallets.isEmpty) {
            return Center(
              child: Text(
                'no_wallets'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleWallets.length,
            itemBuilder: (context, index) {
              final wallet = visibleWallets[index];
              final hexColor = wallet.color.replaceAll('#', '');
              Color itemColor;
              try {
                itemColor = hexColor.length == 6
                    ? Color(int.parse('FF$hexColor', radix: 16))
                    : colors.primary;
              } catch (_) {
                itemColor = colors.primary;
              }

              return _buildWalletCard(
                context: context,
                title: wallet.name,
                amount: showBalance
                    ? '${AppConstant.formatMoney(wallet.balance, wallet.currencyCode)} ${wallet.currencyCode}'
                    : '•••••• ${wallet.currencyCode}',
                icon: _getWalletIcon(wallet.type),
                iconBgColor: itemColor.withOpacity(0.12),
                iconColor: itemColor,
              );
            },
          );
        },
        loading: () => Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            '${'load_wallets_error'.tr(ref)}: $err',
            style: TextStyle(color: colors.expenseRed, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final colors = context.colors;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
