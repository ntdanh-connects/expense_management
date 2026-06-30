import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';

class CategoryDetailStatsGrid extends StatelessWidget {
  final String type;
  final List<TransactionEntity> selectedPeriodTxs;
  final double currentPeriodAmount;
  final double? percentageChange;

  const CategoryDetailStatsGrid({
    super.key,
    required this.type,
    required this.selectedPeriodTxs,
    required this.currentPeriodAmount,
    required this.percentageChange,
  });

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    double maxTx = 0.0;
    for (final tx in selectedPeriodTxs) {
      final amt = tx.amount * (tx.exchangeRate ?? 1.0);
      if (amt > maxTx) maxTx = amt;
    }

    double avgTx = selectedPeriodTxs.isEmpty
        ? 0.0
        : (currentPeriodAmount / selectedPeriodTxs.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chỉ số chi tiết',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatItem(
                title: 'Số giao dịch',
                value: '${selectedPeriodTxs.length}',
                icon: Icons.tag_rounded,
                iconColor: Colors.blue,
                colors: colors,
              ),
              _buildStatItem(
                title: 'Biến động kỳ trước',
                value: percentageChange != null
                    ? (percentageChange! > 0
                        ? '+${percentageChange!.toStringAsFixed(1)}%'
                        : '${percentageChange!.toStringAsFixed(1)}%')
                    : 'N/A',
                icon: percentageChange == null
                    ? Icons.trending_flat_rounded
                    : (percentageChange! > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                iconColor: percentageChange == null
                    ? Colors.grey
                    : (percentageChange! > 0
                        ? (type == 'expense' ? colors.expenseRed : colors.incomeGreen)
                        : (type == 'expense' ? colors.incomeGreen : colors.expenseRed)),
                textColor: percentageChange == null
                    ? colors.textSecondary
                    : (percentageChange! > 0
                        ? (type == 'expense' ? colors.expenseRed : colors.incomeGreen)
                        : (type == 'expense' ? colors.incomeGreen : colors.expenseRed)),
                colors: colors,
              ),
              _buildStatItem(
                title: 'Giao dịch lớn nhất',
                value: _formatCurrency(maxTx),
                icon: Icons.keyboard_double_arrow_up_rounded,
                iconColor: Colors.orange,
                colors: colors,
              ),
              _buildStatItem(
                title: 'Trung bình/giao dịch',
                value: _formatCurrency(avgTx),
                icon: Icons.calculate_rounded,
                iconColor: Colors.purple,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? textColor,
    required AppColorsExtension colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor ?? colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
