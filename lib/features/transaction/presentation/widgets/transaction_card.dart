import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

/// Widget card hiển thị một giao dịch trong lịch sử
class TransactionCard extends StatelessWidget {
  final TransactionEntity tx;

  const TransactionCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isIncome = tx.type == 'income';
    final isTransfer = tx.sourceType == 'transfer';

    // ── Số tiền hiển thị với màu đúng
    final amountText = _buildAmountText(isIncome, isTransfer, colors);

    // ── Icon & màu danh mục (lấy thẳng từ dữ liệu category đã eager-load từ API)
    final categoryIcon = CategoryUIConstants.getIconData(tx.categoryIcon);
    final categoryColor = CategoryUIConstants.getColorFromHex(tx.categoryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
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
                      Text(
                        tx.walletName ?? '–',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '  •  ${_formatTime(tx.transactionDate)}',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),

                  // Danh mục (nếu có)
                  if (tx.categoryName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.label_outline_rounded,
                            size: 11, color: colors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          tx.categoryName!,
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
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
    );
  }

  Widget _buildAmountText(
      bool isIncome, bool isTransfer, AppColorsExtension colors) {
    if (isTransfer) {
      return Text(
        _fmtAmount(tx.amount),
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 15.5,
        ),
      );
    }

    if (isIncome) {
      return Text(
        '+${_fmtAmount(tx.amount)}',
        style: TextStyle(
          color: colors.incomeGreen,
          fontWeight: FontWeight.bold,
          fontSize: 15.5,
        ),
      );
    }

    // Chi tiêu → đỏ
    return Text(
      '-${_fmtAmount(tx.amount)}',
      style: TextStyle(
        color: colors.expenseRed,
        fontWeight: FontWeight.bold,
        fontSize: 15.5,
      ),
    );
  }

  String _fmtAmount(double value) {
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted =
        value.toStringAsFixed(0).replaceAllMapped(reg, (m) => '${m[1]},');
    return '$formatted đ';
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
