import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';

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

class BudgetCategoryTile extends ConsumerWidget {
  final BudgetDto item;

  const BudgetCategoryTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;

    final categoryName = item.category?.name ?? 'uncategorized'.tr(ref);
    final categoryIconStr = item.category?.icon;
    final categoryColorStr = item.category?.color;

    final categoryIcon = CategoryUIConstants.getIconData(categoryIconStr, categoryName: categoryName);
    final categoryColor = CategoryUIConstants.getColorFromHex(categoryColorStr, categoryName: categoryName);

    // Convert from server currency (VND) to user's display currency
    final limit = _convertToUserCurrency(item.limitAmount, 'VND', userCurrency, ratesData);
    final used = _convertToUserCurrency(item.usedAmount, 'VND', userCurrency, ratesData);
    final percent = limit > 0 ? (used / limit) : 0.0;

    // Determine bar color and warning status
    Color barColor = colors.incomeGreen;
    Widget? warningIcon;
    bool isNearLimit = percent >= 0.8 && percent < 1.0;
    bool isOverLimit = percent >= 1.0;

    if (isOverLimit) {
      barColor = colors.expenseRed;
      warningIcon = Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.expenseRed, size: 16),
          const SizedBox(width: 4),
          Text(
            '${(percent * 100).toInt()}%',
            style: TextStyle(
                color: colors.expenseRed, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else if (isNearLimit) {
      barColor = Colors.orange;
      warningIcon = Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 4),
          Text(
            '${(percent * 100).toInt()}%',
            style: const TextStyle(
                color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      warningIcon = Text(
        '${(percent * 100).toInt()}%',
        style: TextStyle(
            color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverLimit
              ? colors.expenseRed.withOpacity(0.2)
              : (isNearLimit
                  ? Colors.orange.withOpacity(0.2)
                  : colors.textSecondary.withOpacity(0.04)),
          width: (isOverLimit || isNearLimit) ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () => context.push(RoutePaths.budgetEdit, extra: item).then((_) {
          ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
        }),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'spent'.tr(ref)} ${AppConstant.formatMoney(used, userCurrency)} $currencySymbol / ${AppConstant.formatMoney(limit, userCurrency)} $currencySymbol',
                          style: TextStyle(
                            color: isOverLimit ? colors.expenseRed : colors.textSecondary,
                            fontSize: 12,
                            fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  warningIcon,
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: colors.textSecondary.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
