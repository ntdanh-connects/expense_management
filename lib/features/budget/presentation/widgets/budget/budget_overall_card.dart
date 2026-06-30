import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';

double _convertToUserCurrency(
  double amount,
  String fromCurrency,
  String userCurrency,
  dynamic ratesData,
) {
  final from = fromCurrency.toUpperCase();
  final to = userCurrency.toUpperCase();
  if (from == to) return amount;

  const fallbackRates = {
    'USD': 1.0, 'VND': 25400.0, 'EUR': 0.92,
    'GBP': 0.78, 'JPY': 156.0,
  };

  final base = (ratesData?.base ?? 'USD').toUpperCase();
  final rates = ratesData?.rates.map(
    (k, v) => MapEntry(k.toUpperCase(), v.toDouble()),
  ) ?? fallbackRates;

  final fromRate = from == base ? 1.0 : (rates[from] ?? 1.0);
  final toRate   = to == base   ? 1.0 : (rates[to]   ?? 1.0);

  return amount * (toRate / fromRate);
}

int _remainingDays(int month, int year) {
  final now = DateTime.now();
  if (now.month == month && now.year == year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return lastDay - now.day;
  } else if (now.year > year || (now.year == year && now.month > month)) {
    return 0; // Past month
  } else {
    // Future month
    return DateTime(year, month + 1, 0).day;
  }
}

class BudgetOverallCard extends ConsumerWidget {
  final BudgetDto generalBudget;

  const BudgetOverallCard({
    super.key,
    required this.generalBudget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final month = ref.watch(selectedBudgetMonthProvider);
    final year = ref.watch(selectedBudgetYearProvider);
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;

    final limit = _convertToUserCurrency(generalBudget.limitAmount, 'VND', userCurrency, ratesData);
    final used = _convertToUserCurrency(generalBudget.usedAmount, 'VND', userCurrency, ratesData);
    final remaining = limit - used;
    final pct = limit > 0 ? (used / limit) : 0.0;
    final days = _remainingDays(month, year);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () => context.push(RoutePaths.budgetEdit, extra: generalBudget).then((_) {
          ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
        }),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'overall_budget'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      days > 0 
                          ? 'days_remaining'.tr(ref).replaceAll('{days}', days.toString()) 
                          : 'expired'.tr(ref),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppConstant.formatMoney(limit, userCurrency)} $currencySymbol',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Circular Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: colors.textSecondary.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 1.0
                                ? colors.expenseRed
                                : (pct >= 0.8 ? Colors.orange : colors.primary),
                          ),
                        ),
                      ),
                      Text(
                        '${(pct * 100).toInt()}%',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Details
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'spent'.tr(ref),
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            ),
                            Text(
                              '${AppConstant.formatMoney(used, userCurrency)} $currencySymbol',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              remaining >= 0 ? 'remaining'.tr(ref) : 'over_limit'.tr(ref),
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            ),
                            Text(
                              '${AppConstant.formatMoney(remaining.abs(), userCurrency)} $currencySymbol',
                              style: TextStyle(
                                color: remaining >= 0 ? colors.incomeGreen : colors.expenseRed,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
