import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class BudgetEditProgressCard extends ConsumerWidget {
  final double usedAmount;
  final double remainingAmount;
  final double progressRatio;
  final Color progressColor;
  final IconData categoryIcon;
  final Color categoryColor;
  final String userCurrency;
  final String currencySymbol;

  const BudgetEditProgressCard({
    super.key,
    required this.usedAmount,
    required this.remainingAmount,
    required this.progressRatio,
    required this.progressColor,
    required this.categoryIcon,
    required this.categoryColor,
    required this.userCurrency,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'current_spending'.tr(ref),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppConstant.formatMoney(usedAmount, userCurrency)} $currencySymbol',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remainingAmount >= 0 ? 'remaining'.tr(ref) : 'over_limit'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstant.formatMoney(remainingAmount.abs(), userCurrency)} $currencySymbol',
                    style: TextStyle(
                      color: remainingAmount >= 0 ? colors.incomeGreen : colors.expenseRed,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.textSecondary.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'budget_usage_percent'.tr(ref).replaceAll('{percent}', '${(progressRatio * 100).toInt()}'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
