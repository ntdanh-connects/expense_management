import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class RecurringRuleCard extends ConsumerWidget {
  final RecurringRuleEntity rule;
  final bool isRecorded;
  final bool isExecuting;
  final VoidCallback onToggle;
  final VoidCallback onRecord;
  final VoidCallback onEdit;

  const RecurringRuleCard({
    super.key,
    required this.rule,
    required this.isRecorded,
    required this.isExecuting,
    required this.onToggle,
    required this.onRecord,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isExpense = rule.type == 'expense';
    final amountColor = isExpense ? colors.expenseRed : colors.incomeGreen;
    final sign = isExpense ? '-' : '+';
    final currencyCode = rule.walletCurrencyCode ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);

    // Lấy icon & màu danh mục
    final catIcon = CategoryUIConstants.getIconData(
      rule.categoryIcon,
      categoryName: rule.categoryName,
    );
    final catColor = CategoryUIConstants.getColorFromHex(
      rule.categoryColor,
      categoryName: rule.categoryName,
    );

    // Tính ngày kỳ tới
    String nextRunStr = '';
    if (rule.nextRunAt != null) {
      final d = rule.nextRunAt!;
      nextRunStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rule.isActive
              ? colors.textSecondary.withOpacity(0.06)
              : colors.textSecondary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Icon danh mục
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Title + frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'recurring_label_${rule.frequency}'.tr(ref),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (rule.payeeName != null &&
                          rule.payeeName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: colors.textSecondary,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rule.payeeName!,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount + next run
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${AppConstant.formatMoney(rule.amount, currencyCode)} $currencySymbol',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (nextRunStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${'recurring_next_run'.tr(ref)}: $nextRunStr',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Bottom row: toggle + edit
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.textSecondary.withOpacity(0.06)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle
                Row(
                  children: [
                    Switch.adaptive(
                      value: rule.isActive,
                      activeColor: colors.primary,
                      activeTrackColor: colors.primary.withOpacity(0.3),
                      onChanged: (_) => onToggle(),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Text(
                          rule.isActive
                              ? 'recurring_active'.tr(ref)
                              : 'recurring_inactive'.tr(ref),
                          style: TextStyle(
                            color: rule.isActive
                                ? colors.primary
                                : colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Actions: Ghi nhận ngay + Edit
                Row(
                  children: [
                    if (rule.isActive) ...[
                      Builder(
                        builder: (context) {
                          final isDone = rule.isExecutedCurrentPeriod || isRecorded;
                          return GestureDetector(
                            onTap: (isDone || isExecuting) ? null : onRecord,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (isDone || isExecuting)
                                    ? colors.textSecondary.withOpacity(0.06)
                                    : colors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isDone || isExecuting)
                                      ? Colors.transparent
                                      : colors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isExecuting) ...[
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            colors.primary),
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      isDone
                                          ? Icons.check_circle_rounded
                                          : Icons.add_task_rounded,
                                      color: isDone
                                          ? colors.textSecondary
                                          : colors.primary,
                                      size: 14,
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  Text(
                                    isExecuting
                                        ? 'recurring_recording'.tr(ref)
                                        : isDone
                                            ? 'recurring_recorded'.tr(ref)
                                            : 'recurring_record'.tr(ref),
                                    style: TextStyle(
                                      color: (isDone || isExecuting)
                                          ? colors.textSecondary
                                          : colors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: colors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
