import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/constants/app_constant.dart';

/// Widget card hiển thị một giao dịch trong lịch sử
class TransactionCard extends ConsumerWidget {
  final TransactionEntity tx;

  const TransactionCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    final isIncome = tx.type == 'income';
    final isTransfer = tx.sourceType == 'transfer';

    // Tra cứu động (Direction A)
    final wallets = ref.watch(walletNotifierProvider).value ?? [];
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];

    final localWallet = wallets.where((w) => w.id == tx.walletId).firstOrNull;
    final localCategory = categories.where((c) => c.id == tx.categoryId).firstOrNull;

    final walletName = localWallet?.name ?? tx.walletName ?? '–';
    final categoryName = localCategory?.name ?? tx.categoryName;
    final categoryIconStr = localCategory?.icon ?? tx.categoryIcon;
    final categoryColorStr = localCategory?.color ?? tx.categoryColor;

    // ── Số tiền hiển thị với màu đúng
    final amountText = _buildAmountText(isIncome, isTransfer, colors, localWallet);
    
    // ── Icon & màu danh mục (lấy từ SQLite local nếu có, fallback dữ liệu cũ)
    final categoryIcon = CategoryUIConstants.getIconData(categoryIconStr);
    final categoryColor = CategoryUIConstants.getColorFromHex(categoryColorStr);

    final isPending = tx.status == 'pending';

    return InkWell(
      onTap: () {
        context.push(
          RoutePaths.transactionDetail,
          extra: tx,
        ).then((shouldRefresh) {
          if (shouldRefresh == true) {
            ref.invalidate(transactionListProvider);
            ref.invalidate(filteredTransactionListProvider);
            ref.invalidate(walletNotifierProvider);
          }
        });
      },
      child:Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(isPending ? 0.85 : 1.0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPending
                ? Colors.orange.withOpacity(0.4)
                : colors.textSecondary.withValues(alpha: 0.06),
            width: isPending ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? Colors.orange.withOpacity(0.04)
                  : colors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ── Icon danh mục
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Thông tin giao dịch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    Text(
                      tx.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Ví • Giờ
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 11, color: colors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            walletName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 12),
                          ),
                        ),
                        Text(
                          '  •  ${_formatTime(tx.transactionDate, ref)}',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
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

                    // Danh mục (nếu có)
                    if (categoryName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(categoryIcon,
                              size: 11, color: categoryColor),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              categoryName.tr(ref),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Ghi chú (nếu có)
                    if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.65),
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Số tiền (màu theo loại)
              amountText,
            ],
          ),
        ),
      )
    );
  }

  Widget _buildAmountText(
      bool isIncome, bool isTransfer, AppColorsExtension colors, dynamic localWallet) {
        final String currencySymbol = (localWallet != null && 
            localWallet.currencyCode != null && 
            localWallet.currencyCode.toString().isNotEmpty)
        ? localWallet.currencyCode.toString()
        : 'đ';

    if (isTransfer) {
      return Text(
        _fmtAmount(tx.amount, currencySymbol),
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 15.5,
        ),
      );
    }

    if (isIncome) {
      return Text(
        '+${_fmtAmount(tx.amount, currencySymbol)}',
        style: TextStyle(
          color: colors.incomeGreen, // Màu xanh thu nhập
          fontWeight: FontWeight.bold,
          fontSize: 15.5,
        ),
      );
    }

    // Chi tiêu → đỏ
    return Text(
    '-${_fmtAmount(tx.amount, currencySymbol)}',
    style: TextStyle(
      color: colors.expenseRed, // Màu đỏ chi tiêu
      fontWeight: FontWeight.bold,
      fontSize: 15.5,
    ),
  );
  }

  String _fmtAmount(double value, String symbol) {
    final formattedNumber = AppConstant.formatMoney(value, tx.currencyCode);
    return '$formattedNumber $symbol';
  }

  String _formatTime(DateTime date, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final tzName = tx.timezone ?? user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;
      final offsetStr = offset.inMinutes == 0
          ? 'UTC'
          : 'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}';
      return '${tzDateTime.hour.toString().padLeft(2, '0')}:${tzDateTime.minute.toString().padLeft(2, '0')} ($offsetStr)';
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
