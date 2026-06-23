import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:shimmer/shimmer.dart';

// Currency conversion helper (same as transaction_history_screen)
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

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
    });
  }

  int remainingDays(int month, int year) {
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


  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = ref.watch(selectedBudgetMonthProvider);
    final year = ref.watch(selectedBudgetYearProvider);
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;
    final now = DateTime.now();
    final isPastMonth = year < now.year || (year == now.year && month < now.month);

    final budgetsAsync = ref.watch(budgetListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🗓️ 1. BỘ CHỌN THÁNG/NĂM CÓ CHEVRON
        Container(
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
                    DateFormat.yMMMM(ref.watch(localeProvider)).format(DateTime(year, month)),
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
        ),
        const SizedBox(height: 18),

        // 🟢 LOAD BUDGETS DATA
        budgetsAsync.when(
          data: (budgetList) {
            // Find General budget (categoryId == null)
            final generalBudget = budgetList.where((b) => b.categoryId == null).firstOrNull;
            final categoryBudgets = budgetList.where((b) => b.categoryId != null).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💳 2. NGÂN SÁCH TỔNG CARD
                if (generalBudget != null) ...[
                  _buildGeneralBudgetCard(generalBudget, month, year, userCurrency, currencySymbol, ratesData, colors)
                ] else ...[
                  _buildEmptyGeneralBudgetCard(colors, isPastMonth)
                ],
                const SizedBox(height: 16),

                // 📋 3. NÚT SAO CHÉP NGÂN SÁCH THÁNG TRƯỚC
                if (!isPastMonth) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary.withOpacity(0.12),
                        foregroundColor: colors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: colors.primary.withOpacity(0.2)),
                        ),
                      ),
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      label: Text(
                        'copy_previous'.tr(ref),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(budgetListProvider.notifier).copyFromPreviousMonth();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('success'.tr(ref)),
                                backgroundColor: colors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${'copy_previous_failed'.tr(ref)}: $e'),
                                backgroundColor: colors.expenseRed,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 24),

                // 🏷️ 4. TIÊU ĐỀ SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'spending_categories'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (categoryBudgets.isNotEmpty && !isPastMonth)
                      TextButton(
                        onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                          ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                        }),
                        child: Text(
                          'add_new'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // 📊 5. DANH SÁCH HẠN MỨC CHI TIÊU
                if (categoryBudgets.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.pie_chart_outline_rounded,
                              size: 44, color: colors.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'no_category_budget_setup'.tr(ref),
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                          if (!isPastMonth) ...[
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text('add_category_budget_button'.tr(ref)),
                              onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                                ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryBudgets.length,
                    itemBuilder: (context, index) {
                      final item = categoryBudgets[index];
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
                        padding: const EdgeInsets.all(16),
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
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  if (!isPastMonth)
                    // NÚT THÊM DANH MỤC NHANH Ở CUỐI BÀI
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                          ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                        }),
                        icon: Icon(Icons.add_circle_outline_rounded, color: colors.primary),
                        label: Text(
                          'add_category_limit_button'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
          loading: () => const _BudgetShimmer(),
          error: (error, _) => Container(
            height: 100,
            alignment: Alignment.center,
            child: Text(
              '${'error_occurred'.tr(ref)}: $error',
              style: TextStyle(color: colors.expenseRed),
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET VẼ CARD NGÂN SÁCH TỔNG
  Widget _buildGeneralBudgetCard(
      BudgetDto generalBudget, int month, int year, String currency, String currencySymbol, dynamic ratesData, AppColorsExtension colors) {
    // Convert from server currency (VND) to user's display currency
    final limit = _convertToUserCurrency(generalBudget.limitAmount, 'VND', currency, ratesData);
    final used = _convertToUserCurrency(generalBudget.usedAmount, 'VND', currency, ratesData);
    final remaining = limit - used;
    final pct = limit > 0 ? (used / limit) : 0.0;
    final days = remainingDays(month, year);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              '${AppConstant.formatMoney(limit, currency)} $currencySymbol',
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
                            '${AppConstant.formatMoney(used, currency)} $currencySymbol',
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
                            '${AppConstant.formatMoney(remaining.abs(), currency)} $currencySymbol',
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
    );
  }

  // WIDGET VẼ CARD KHI CHƯA CÓ NGÂN SÁCH TỔNG
  Widget _buildEmptyGeneralBudgetCard(AppColorsExtension colors, bool isPastMonth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 48, color: colors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            isPastMonth 
                ? 'no_overall_budget_history'.tr(ref)
                : 'no_overall_budget_setup'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isPastMonth) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                  ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                }),
                child: Text(
                  'setup_overall_budget_now'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetShimmer extends StatelessWidget {
  const _BudgetShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget overall card
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          // Copy from previous month button
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Section Title
          Container(
            width: 150,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Category budgets list
          for (int i = 0; i < 3; i++) ...[
            Container(
              width: double.infinity,
              height: 96,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


