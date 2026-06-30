import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';

class SavingsHistoryList extends ConsumerWidget {
  final SavingsGoalEntity goal;

  const SavingsHistoryList({
    super.key,
    required this.goal,
  });

  String _formatDateTime(DateTime date, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;
      final offsetStr = offset.inMinutes == 0
          ? 'UTC'
          : 'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}';
      return '${DateFormat('dd/MM/yyyy HH:mm').format(tzDateTime)} ($offsetStr)';
    } catch (_) {
      return '${DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())} (UTC+7)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final list = goal.transactions ?? [];

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'savings_no_transactions'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final localeCode = ref.watch(localeProvider);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        final isDeposit = tx.type == 'deposit';
        final amountSign = isDeposit ? '+' : '-';
        final displayColor = isDeposit ? colors.incomeGreen : colors.primary;
        final amountText = '$amountSign${currencyFormat.format(tx.amount)} đ';
        final dateText = _formatDateTime(tx.transactionDate, ref);

        final amountWords = formatNumberToWords(tx.amount, localeCode);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.textSecondary.withValues(alpha: 0.04)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: displayColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.notes ??
                          (isDeposit
                              ? 'savings_default_deposit_note'.tr(ref)
                              : 'savings_default_withdraw_note'.tr(ref)),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      color: displayColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '($amountWords)',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
