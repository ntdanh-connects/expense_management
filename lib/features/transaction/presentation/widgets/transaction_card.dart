import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/constants/app_constant.dart';

/// Widget card hiển thị một giao dịch trong lịch sử
class TransactionCard extends ConsumerWidget {
  final TransactionEntity tx;

  const TransactionCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    // Tra cứu động (Direction A)
    final wallets = ref.watch(walletNotifierProvider).value ?? [];
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];

    final localWallet = wallets.where((w) => w.id == tx.walletId).firstOrNull;
    final localCategory = categories
        .where((c) => c.id == tx.categoryId)
        .firstOrNull;

    final walletName = localWallet?.name ?? tx.walletName ?? '–';
    final categoryName = localCategory?.name ?? tx.categoryName;
    final categoryIconStr = localCategory?.icon ?? tx.categoryIcon;
    final categoryColorStr = localCategory?.color ?? tx.categoryColor;

    // ── Icon & màu danh mục (lấy từ SQLite local nếu có, fallback dữ liệu cũ)
    final categoryIcon = CategoryUIConstants.getIconData(categoryIconStr);
    final categoryColor = CategoryUIConstants.getColorFromHex(categoryColorStr);

    final isPending = tx.status == 'pending';

    return InkWell(
      onTap: () {
        context.push(RoutePaths.transactionDetail, extra: tx).then((
          shouldRefresh,
        ) {
          if (shouldRefresh == true) {
            ref.invalidate(transactionListProvider);
            ref.invalidate(filteredTransactionListProvider);
            ref.invalidate(walletNotifierProvider);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: isPending ? 0.85 : 1.0),
          border: Border(
            bottom: BorderSide(
              color: colors.textSecondary.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon danh mục (vòng tròn viền mỏng, nền nhạt)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Thông tin giao dịch
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề: Cho phép hiển thị tối đa 2 dòng không bị cắt ngang
                  Text(
                    tx.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Ngày giờ (UTC+X) và Ví
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_formatDateTime(tx.transactionDate, ref)}  •  $walletName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tag danh mục dạng chip nhỏ bên dưới
                  if (categoryName != null && categoryName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 11, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            categoryName.tr(ref),
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ghi chú (nếu có)
                  if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      tx.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Số tiền & Trạng thái (Thất bại / Đang xử lý)
            _buildAmountWidget(colors, localWallet, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountWidget(
    AppColorsExtension colors,
    dynamic localWallet,
    WidgetRef ref,
  ) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.sourceType == 'transfer';
    final isFailed = tx.status == 'failed' || tx.status == 'failure';
    final isPending = tx.status == 'pending';

    final String currencySymbol =
        (localWallet != null &&
            localWallet.currencyCode != null &&
            localWallet.currencyCode.toString().isNotEmpty)
        ? localWallet.currencyCode.toString()
        : 'đ';

    final formattedAmount = _fmtAmount(tx.amountInUserCurrency, currencySymbol);

    // Xác định tiền tố dấu và màu sắc
    String sign = '';
    Color amountColor;

    if (isFailed) {
      amountColor =
          colors.textSecondary; // Số tiền màu xám cho giao dịch thất bại
      sign = isIncome ? '+' : '-';
    } else {
      if (isTransfer) {
        sign = isIncome ? '+' : '-';
        amountColor = isIncome
            ? colors.incomeGreen
            : colors.textPrimary; // Chi tiêu/Chuyển đi màu tối
      } else if (isIncome) {
        sign = '+';
        amountColor = colors.incomeGreen;
      } else {
        sign = '-';
        amountColor = colors.textPrimary; // Chi tiêu màu tối
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$sign$formattedAmount',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
          ),
        ),
        if (isFailed) ...[
          const SizedBox(height: 4),
          Text(
            'failed_status'.tr(ref).toUpperCase(),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else if (isPending) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
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
      ],
    );
  }

  String _fmtAmount(double value, String symbol) {
    final formattedNumber = AppConstant.formatMoney(value, tx.currencyCode);
    return '$formattedNumber $symbol';
  }

  String _formatDateTime(DateTime date, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final tzName = tx.timezone ?? user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;
      final offsetStr = offset.inMinutes == 0
          ? 'UTC'
          : 'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}';

      final hour = tzDateTime.hour.toString().padLeft(2, '0');
      final minute = tzDateTime.minute.toString().padLeft(2, '0');
      final day = tzDateTime.day.toString().padLeft(2, '0');
      final month = tzDateTime.month.toString().padLeft(2, '0');
      final year = tzDateTime.year.toString();

      return '$hour:$minute - $day/$month/$year ($offsetStr)';
    } catch (_) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$hour:$minute - $day/$month/$year';
    }
  }
}
