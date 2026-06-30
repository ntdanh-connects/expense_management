import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class BudgetCreateOverallLimitCard extends ConsumerWidget {
  final TextEditingController overallBudgetController;
  final bool autoCalculateTotal;
  final ValueChanged<bool> onAutoCalculateChanged;
  final CurrencyTextInputFormatter overallFormatter;
  final String currencySymbol;
  final String userCurrency;
  final double remainingAmount;
  final double progressRatio;
  final Color progressColor;
  final ValueChanged<String> onOverallChanged;

  const BudgetCreateOverallLimitCard({
    super.key,
    required this.overallBudgetController,
    required this.autoCalculateTotal,
    required this.onAutoCalculateChanged,
    required this.overallFormatter,
    required this.currencySymbol,
    required this.userCurrency,
    required this.remainingAmount,
    required this.progressRatio,
    required this.progressColor,
    required this.onOverallChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'expected_overall_budget'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    'budget_mode_sum_categories'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    width: 44,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Switch(
                        value: autoCalculateTotal,
                        activeThumbColor: colors.primary,
                        onChanged: onAutoCalculateChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextFormField(
                  controller: overallBudgetController,
                  keyboardType: TextInputType.number,
                  readOnly: autoCalculateTotal,
                  style: TextStyle(
                    color: autoCalculateTotal ? colors.textSecondary : colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.3)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [overallFormatter],
                  onChanged: onOverallChanged,
                ),
              ),
              Text(
                currencySymbol,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (autoCalculateTotal) ...[
            Text(
              'budget_mode_sum_desc'.tr(ref),
              style: TextStyle(
                color: colors.textSecondary.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remainingAmount >= 0 ? 'remaining_limit'.tr(ref) : 'exceeded_limit'.tr(ref),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${AppConstant.formatMoney(remainingAmount.abs(), userCurrency)} $currencySymbol',
                  style: TextStyle(
                    color: remainingAmount >= 0 ? colors.incomeGreen : colors.expenseRed,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressRatio.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colors.textSecondary.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
