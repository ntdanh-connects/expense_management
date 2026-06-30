import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';

class SavingsGoalCard extends ConsumerWidget {
  final SavingsGoalEntity goal;

  const SavingsGoalCard({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final targetStr = currencyFormat.format(goal.targetAmount);
    final currentStr = currencyFormat.format(goal.currentAmount);
    final isCompleted = goal.status == 'completed' || goal.currentAmount >= goal.targetAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/savings/${goal.id}'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.incomeGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'savings_reached_goal'.tr(ref),
                          style: TextStyle(
                            color: colors.incomeGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (goal.daysRemaining > 0)
                      Text(
                        'days_remaining'.tr(ref).replaceAll('{days}', goal.daysRemaining.toString()),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'expired'.tr(ref),
                        style: TextStyle(
                          color: colors.expenseRed,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'savings_accumulated'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentStr đ',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'savings_goal_short'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$targetStr đ',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progressPercent / 100,
                    minHeight: 8,
                    backgroundColor: colors.primary.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? colors.incomeGreen : colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'savings_auto_save_label'.tr(ref).replaceAll(
                            '{frequency}',
                            goal.autoSaveFrequency == 'daily'
                                ? 'savings_freq_daily'.tr(ref)
                                : goal.autoSaveFrequency == 'weekly'
                                    ? 'savings_freq_weekly'.tr(ref)
                                    : goal.autoSaveFrequency == 'monthly'
                                        ? 'savings_freq_monthly'.tr(ref)
                                        : 'savings_auto_save_off'.tr(ref),
                          ),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${goal.progressPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isCompleted ? colors.incomeGreen : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
