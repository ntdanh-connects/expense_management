import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';

class SavingsProgressCard extends ConsumerWidget {
  final SavingsGoalEntity goal;

  const SavingsProgressCard({
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Circular progress graphic
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: goal.progressPercent / 100,
                  strokeWidth: 12,
                  backgroundColor: colors.primary.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? colors.incomeGreen : colors.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${goal.progressPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isCompleted ? colors.incomeGreen : colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? 'savings_status_completed'.tr(ref)
                        : 'savings_status_saving'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            goal.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetailRow(
            'savings_accumulated'.tr(ref),
            '$currentStr đ',
            colors,
            valueColor: colors.primary,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'savings_target_amount_label'.tr(ref),
            '$targetStr đ',
            colors,
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'savings_target_date_label'.tr(ref),
              DateFormat('dd/MM/yyyy').format(goal.targetDate!),
              colors,
            ),
          ],
          if (goal.sourceWalletName != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'savings_linked_wallet_label'.tr(ref),
              goal.sourceWalletName!,
              colors,
            ),
          ],
          if (goal.autoSaveFrequency != null && goal.autoSaveAmount != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'savings_auto_save_title'.tr(ref),
              '${currencyFormat.format(goal.autoSaveAmount)}đ (${goal.autoSaveFrequency == 'daily'
                  ? 'savings_freq_daily'.tr(ref)
                  : goal.autoSaveFrequency == 'weekly'
                      ? 'savings_freq_weekly'.tr(ref)
                      : 'savings_freq_monthly'.tr(ref)})',
              colors,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    AppColorsExtension colors, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
