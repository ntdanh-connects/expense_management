import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class CategoryDetailHeader extends StatelessWidget {
  final String periodLabel;
  final String type;
  final double currentPeriodAmount;
  final double averageAmount;
  final bool isAmountVisible;
  final ValueChanged<bool> onAmountVisibilityChanged;

  const CategoryDetailHeader({
    super.key,
    required this.periodLabel,
    required this.type,
    required this.currentPeriodAmount,
    required this.averageAmount,
    required this.isAmountVisible,
    required this.onAmountVisibilityChanged,
  });

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      color: colors.primary,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$periodLabel${type == 'expense' ? ' chi' : ' thu'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                isAmountVisible ? _formatCurrency(currentPeriodAmount) : '******',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onAmountVisibilityChanged(!isAmountVisible),
                child: Icon(
                  isAmountVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'T.bình: ${_formatCurrency(averageAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
