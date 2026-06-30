import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';

class BudgetMonthSelector extends ConsumerWidget {
  const BudgetMonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final month = ref.watch(selectedBudgetMonthProvider);
    final year = ref.watch(selectedBudgetYearProvider);
    final locale = ref.watch(localeProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: colors.primary),
            onPressed: () {
              int prevMonth = month - 1;
              int prevYear = year;
              if (prevMonth == 0) {
                prevMonth = 12;
                prevYear = year - 1;
              }
              ref.read(selectedBudgetMonthProvider.notifier).state = prevMonth;
              ref.read(selectedBudgetYearProvider.notifier).state = prevYear;
            },
          ),
          Column(
            children: [
              Text(
                DateFormat.yMMMM(locale).format(DateTime(year, month)),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (DateTime.now().month == month && DateTime.now().year == year) ...[
                const SizedBox(height: 2),
                Text(
                  'current_budget'.tr(ref),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: colors.primary),
            onPressed: () {
              int nextMonth = month + 1;
              int nextYear = year;
              if (nextMonth == 13) {
                nextMonth = 1;
                nextYear = year + 1;
              }
              ref.read(selectedBudgetMonthProvider.notifier).state = nextMonth;
              ref.read(selectedBudgetYearProvider.notifier).state = nextYear;
            },
          ),
        ],
      ),
    );
  }
}
