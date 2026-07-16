import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/shared/widgets/transaction_list_shimmer.dart';

class DashboardRecentTransactions extends ConsumerWidget {
  const DashboardRecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final walletState = ref.watch(walletNotifierProvider);

    return ref.watch(transactionListProvider).when(
          data: (txList) {
            if (txList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Chưa có giao dịch nào.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              );
            }

            // Sắp xếp: Ưu tiên giao dịch chờ đồng bộ (pending) lên đầu, sau đó sắp xếp theo ngày mới nhất
            final sorted = [...txList]
              ..sort((a, b) {
                final aPending = a.status == 'pending';
                final bPending = b.status == 'pending';
                if (aPending && !bPending) return -1;
                if (!aPending && bPending) return 1;
                return b.transactionDate.compareTo(a.transactionDate);
              });
            final recentTx = sorted.take(5).toList();

            return Column(
              children: recentTx.map((tx) {
                final isIncome = tx.type == 'income';
                final isTransfer = tx.sourceType == 'transfer';
                final sign = isIncome ? '+' : (isTransfer ? '' : '-');

                // Tra cứu động (Direction A)
                final wallets = walletState.value ?? [];
                final categories =
                    ref.watch(categoriesNotifierProvider).value ?? [];

                final localWallet =
                    wallets.where((w) => w.id == tx.walletId).firstOrNull;
                final localCategory = categories
                    .where((c) => c.id == tx.categoryId)
                    .firstOrNull;

                final walletName = localWallet?.name ?? tx.walletName ?? 'Ví';
                final categoryIconStr =
                    localCategory?.icon ?? tx.categoryIcon;
                final categoryColorStr =
                    localCategory?.color ?? tx.categoryColor;

                final categoryIcon = CategoryUIConstants.getIconData(
                  categoryIconStr,
                );
                final categoryColor = CategoryUIConstants.getColorFromHex(
                  categoryColorStr,
                );

                final txCurrency = (localWallet != null &&
                        localWallet.currencyCode.toString().isNotEmpty)
                    ? localWallet.currencyCode.toString()
                    : (tx.currencyCode ?? 'VND');

                return _buildRecentTransactionItem(
                  ref: ref,
                  colors: colors,
                  title: tx.title,
                  sub:
                      '$walletName • ${_formatDateTime(tx.transactionDate, tx.timezone, ref)}',
                  amount:
                      '$sign${AppConstant.formatMoney(tx.amountInUserCurrency, tx.currencyCode)} $txCurrency',
                  isIncome: isIncome,
                  icon: categoryIcon,
                  iconColor: categoryColor,
                  isPending: tx.status == 'pending',
                );
              }).toList(),
            );
          },
          loading: () => const TransactionListShimmer(
            itemCount: 5,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Không thể tải giao dịch.',
                style: TextStyle(color: colors.expenseRed),
              ),
            ),
          ),
        );
  }

  Widget _buildRecentTransactionItem({
    required WidgetRef ref,
    required AppColorsExtension colors,
    required String title,
    required String sub,
    required String amount,
    required bool isIncome,
    required IconData icon,
    required Color iconColor,
    bool isPending = false,
  }) {
    final displayColor = isIncome ? colors.incomeGreen : colors.expenseRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(isPending ? 0.85 : 1.0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPending
                ? Colors.orange.withOpacity(0.4)
                : colors.textSecondary.withOpacity(0.04),
            width: isPending ? 1.2 : 1.0,
          ),
          boxShadow: isPending
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'transaction_status_pending'.tr(ref),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: displayColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date, String? txTimezone, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final tzName = txTimezone ?? user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;
      final offsetStr = offset.inMinutes == 0
          ? 'UTC'
          : 'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}';
      return '${DateFormat('dd/MM/yyyy HH:mm').format(tzDateTime)} ($offsetStr)';
    } catch (_) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}
