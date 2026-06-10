import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/budget/presentation/screens/budget_screen.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shimmer/shimmer.dart';

class AnalyticScreen extends ConsumerStatefulWidget {
  const AnalyticScreen({super.key});

  @override
  ConsumerState<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends ConsumerState<AnalyticScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final state = GoRouterState.of(context);
      final tab = state.uri.queryParameters['tab'];
      if (tab != null && (tab == 'statistics' || tab == 'history' || tab == 'budget')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedAnalyticTabProvider.notifier).state = tab;
          }
        });
      }
    } catch (e) {
      // ignore
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  Widget _buildShimmerCard({required double height}) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withOpacity(0.08),
      highlightColor: colors.textSecondary.withOpacity(0.03),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  String _formatCompactCurrency(double val) {
    if (val >= 1000000000) {
      return '${(val / 1000000000).toStringAsFixed(1)}B đ';
    } else if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M đ';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K đ';
    }
    return '${val.toStringAsFixed(0)}đ';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedSubTab = ref.watch(selectedAnalyticTabProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(
        hintText: 'search_hint'.tr(ref),
      ),
      floatingActionButton: () {
        if (selectedSubTab != 'budget') return null;
        
        final month = ref.watch(selectedBudgetMonthProvider);
        final year = ref.watch(selectedBudgetYearProvider);
        final now = DateTime.now();
        final isPastMonth = year < now.year || (year == now.year && month < now.month);
        
        if (isPastMonth) return null;
        
        return FloatingActionButton(
          backgroundColor: colors.primary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            context.push(RoutePaths.budgetCreate).then((_) {
              ref.read(budgetListProvider.notifier).refreshBudgets();
            });
          },
        );
      }(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 1. BỘ PHÂN LOẠI NGANG PHỤ (THỐNG KÊ / LỊCH SỬ / NGÂN SÁCH)
            Row(
              children: [
                _buildSubTabButton('statistics', selectedSubTab),
                const SizedBox(width: 8),
                _buildSubTabButton('history', selectedSubTab),
                const SizedBox(width: 8),
                _buildSubTabButton('budget', selectedSubTab),
              ],
            ),
            const SizedBox(height: 18),

            // 🟢 Conditional Rendering depending on active SubTab
            if (selectedSubTab == 'statistics') ...[
              // 🕒 Date range filter selectors
              _buildTimeFilterBar(ref),
              const SizedBox(height: 18),

              // 💵 Balance Summary cards
              _buildSummarySection(ref),
              const SizedBox(height: 18),

              // 📊 Monthly Bar Chart
              _buildBarChartSection(ref),
              const SizedBox(height: 18),

              // 📈 Daily Spending Trend Line Chart
              _buildLineChartSection(ref),
              const SizedBox(height: 18),

              // 🍩 Donut Category distribution
              _buildDonutChartSection(ref),
              const SizedBox(height: 18),

              // 🏆 Top 5 Expense Categories
              _buildTopExpensesSection(ref),
            ] else if (selectedSubTab == 'history') ...[
              _buildHistoryPlaceholder(),
            ] else if (selectedSubTab == 'budget') ...[
              const BudgetScreen(),
            ],
            const SizedBox(height: 80), // Dành khoảng trống cho Bottom Bar trượt
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String key, String selectedSubTab) {
    final colors = context.colors;
    final isSelected = selectedSubTab == key;

    return GestureDetector(
      onTap: () {
        ref.read(selectedAnalyticTabProvider.notifier).state = key;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.textSecondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          key.tr(ref),
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterBar(WidgetRef ref) {
    final currentFilter = ref.watch(selectedTimeFilterProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(ref, TimeFilter.thisWeek, 'this_week'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(ref, TimeFilter.thisMonth, 'this_month'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(ref, TimeFilter.thisQuarter, 'this_quarter'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(ref, TimeFilter.thisYear, 'this_year'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(ref, TimeFilter.custom, 'custom_range'.tr(ref), currentFilter),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Display the selected range text
        Text(
          '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(WidgetRef ref, TimeFilter filter, String label, TimeFilter currentFilter) {
    final isSelected = filter == currentFilter;
    final colors = context.colors;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          if (filter == TimeFilter.custom) {
            _selectCustomDateRange(ref);
          } else {
            ref.read(selectedTimeFilterProvider.notifier).state = filter;
          }
        }
      },
      selectedColor: colors.primary,
      backgroundColor: colors.textSecondary.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  Future<void> _selectCustomDateRange(WidgetRef ref) async {
    final now = DateTime.now();
    final currentRange = ref.read(selectedDateRangeProvider);
    final colors = context.colors;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.primary,
                  onPrimary: Colors.white,
                  surface: colors.surface,
                  onSurface: colors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = picked;
      ref.read(selectedTimeFilterProvider.notifier).state = TimeFilter.custom;
    }
  }

  Widget _buildSummarySection(WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider);
    final previousSummaryAsync = ref.watch(previousPeriodSummaryProvider);
    final colors = context.colors;

    final summary = summaryAsync.asData?.value;
    if (summary == null) {
      if (summaryAsync.isLoading) {
        return _buildShimmerCard(height: 220);
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          summaryAsync.error != null
              ? 'error_with_details'.tr(ref).replaceAll('{error}', summaryAsync.error.toString())
              : 'no_data'.tr(ref),
          style: TextStyle(color: colors.expenseRed),
        ),
      );
    }

    final previousSummary = previousSummaryAsync.asData?.value;

        return Column(
          children: [
            // Net balance main card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'net_balance'.tr(ref).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(summary.net),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Compare text
                  if (previousSummary != null)
                    _buildComparisonWidget(summary, previousSummary, colors, ref),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Two expanded boxes (Income & Expense)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_up_rounded, color: colors.incomeGreen, size: 22),
                        const SizedBox(height: 12),
                        Text(
                          'income_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.income),
                          style: TextStyle(
                            color: colors.incomeGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_down_rounded, color: colors.expenseRed, size: 22),
                        const SizedBox(height: 12),
                        Text(
                          'expense_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.expense),
                          style: TextStyle(
                            color: colors.expenseRed,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
  }

  Widget _buildComparisonWidget(ReportSummaryDto current, ReportSummaryDto? previous, AppColorsExtension colors, WidgetRef ref) {
    if (previous == null || previous.expense == 0) return const SizedBox();

    final diff = current.expense - previous.expense;
    final percent = (diff.abs() / previous.expense) * 100;
    final isIncrease = diff > 0;

    final textColor = Colors.white.withOpacity(0.9);
    final icon = isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    final changeText = isIncrease ? 'increased_by'.tr(ref) : 'decreased_by'.tr(ref);
    final compareLabel = 'compare_with_prev'.tr(ref);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(1)}% $changeText $compareLabel',
            style: TextStyle(color: textColor, fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection(WidgetRef ref) {
    final trends6MonthsAsync = ref.watch(trends6MonthsProvider);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'income_vs_expense'.tr(ref),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'six_month_data'.tr(ref),
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
              Row(
                children: [
                  _buildLegendDot(colors.incomeGreen, 'income'.tr(ref)),
                  const SizedBox(width: 12),
                  _buildLegendDot(colors.expenseRed, 'expense'.tr(ref)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Draw bars
          SizedBox(
            height: 150,
            child: () {
              final trends = trends6MonthsAsync.asData?.value;
              if (trends == null) {
                if (trends6MonthsAsync.isLoading) {
                  return _buildShimmerCard(height: 150);
                }
                return Center(
                  child: Text(
                    trends6MonthsAsync.error != null
                        ? 'error_with_details'.tr(ref).replaceAll('{error}', trends6MonthsAsync.error.toString())
                        : 'no_data'.tr(ref),
                    style: TextStyle(color: colors.expenseRed, fontSize: 13),
                  ),
                );
              }

              if (trends.isEmpty) {
                return Center(
                  child: Text(
                    'no_trend_data'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                );
              }

              // Find max val across all income/expense to scale height
              double maxVal = 0;
              for (var trend in trends) {
                if (trend.income > maxVal) maxVal = trend.income;
                if (trend.expense > maxVal) maxVal = trend.expense;
              }
              if (maxVal == 0) maxVal = 1.0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((trend) {
                  final incomePct = trend.income / maxVal;
                  final expensePct = trend.expense / maxVal;
                  return _buildDoubleBar(trend.label, incomePct, expensePct, colors);
                }).toList(),
              );
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDoubleBar(String label, double incomeVal, double expenseVal, AppColorsExtension colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Cột thu nhập
            Container(
              width: 8,
              height: 110 * incomeVal,
              decoration: BoxDecoration(
                color: colors.incomeGreen,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(width: 4),
            // Cột chi tiêu
            Container(
              width: 8,
              height: 110 * expenseVal,
              decoration: BoxDecoration(
                color: colors.expenseRed,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLineChartSection(WidgetRef ref) {
    final dailyTrendsAsync = ref.watch(trendsDailyProvider);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'spending_trend'.tr(ref),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          () {
            final trends = dailyTrendsAsync.asData?.value;
            if (trends == null) {
              if (dailyTrendsAsync.isLoading) {
                return _buildShimmerCard(height: 160);
              }
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    dailyTrendsAsync.error != null
                        ? 'error_with_details'.tr(ref).replaceAll('{error}', dailyTrendsAsync.error.toString())
                        : 'no_data'.tr(ref),
                    style: TextStyle(color: colors.expenseRed),
                  ),
                ),
              );
            }
            return SpendingTrendLineChart(data: trends, colors: colors);
          }(),
        ],
      ),
    );
  }

  Widget _buildDonutChartSection(WidgetRef ref) {
    final categoriesAsync = ref.watch(reportCategoriesProvider);
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'category_distribution'.tr(ref),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          () {
            final reportData = categoriesAsync.asData?.value;
            if (reportData == null) {
              if (categoriesAsync.isLoading) {
                return _buildShimmerCard(height: 160);
              }
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    categoriesAsync.error != null
                        ? 'error_with_details'.tr(ref).replaceAll('{error}', categoriesAsync.error.toString())
                        : 'no_data'.tr(ref),
                    style: TextStyle(color: colors.expenseRed),
                  ),
                ),
              );
            }

            final entries = reportData.categories;
            if (entries.isEmpty) {
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text('no_spending_this_period'.tr(ref)),
                ),
              );
            }

            // Create segments for Donut chart
            final segments = entries.map((e) {
              final categoryColor = CategoryUIConstants.getColorFromHex(e.categoryColor);
              return ChartSegment(
                color: categoryColor,
                percentage: e.percentage / 100.0,
              );
            }).toList();

            return Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(150, 150),
                      painter: DonutChartPainter(
                        segments: segments,
                        strokeWidth: 20,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'total_expense'.tr(ref),
                          style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCompactCurrency(reportData.totalAmount),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'click_to_view'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpensesSection(WidgetRef ref) {
    final categoriesAsync = ref.watch(reportCategoriesProvider);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'top_5_expenses'.tr(ref),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          () {
            final reportData = categoriesAsync.asData?.value;
            if (reportData == null) {
              if (categoriesAsync.isLoading) {
                return _buildShimmerCard(height: 200);
              }
              return Center(
                child: Text(
                  categoriesAsync.error != null
                      ? 'error_with_details'.tr(ref).replaceAll('{error}', categoriesAsync.error.toString())
                      : 'no_data'.tr(ref),
                  style: TextStyle(color: colors.expenseRed, fontSize: 13),
                ),
              );
            }

            final entries = reportData.categories;
            if (entries.isEmpty) {
              return Center(
                child: Text(
                  'no_spending_data'.tr(ref),
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              );
            }

            // Take top 5
            final top5 = entries.take(5).toList();

            return Column(
              children: top5.map((e) {
                final progressColor = CategoryUIConstants.getColorFromHex(e.categoryColor);
                return _buildTopExpenseRow(
                  e.categoryName.tr(ref),
                  _formatCurrency(e.amount),
                  e.percentage / 100.0,
                  progressColor,
                  colors,
                );
              }).toList(),
            );
          }(),
        ],
      ),
    );
  }

  Widget _buildTopExpenseRow(String title, String amount, double pct, Color progressColor, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: colors.textSecondary.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPlaceholder() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: colors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'report_history_placeholder'.tr(ref),
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

}

// 📐 VẼ CUSTOM LINE CHART XU HƯỚNG CHI TIÊU HÀNG NGÀY
class SpendingTrendLineChart extends ConsumerWidget {
  final List<ReportTrendEntryDto> data;
  final AppColorsExtension colors;

  const SpendingTrendLineChart({
    super.key,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'no_trend_data'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    // Find max expense to scale
    double maxExpense = 0;
    for (var entry in data) {
      if (entry.expense > maxExpense) {
        maxExpense = entry.expense;
      }
    }
    if (maxExpense == 0) maxExpense = 1.0; // Avoid divide by zero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: CustomPaint(
            size: Size.infinite,
            painter: LineChartPainter(
              data: data,
              maxVal: maxExpense,
              colors: colors,
            ),
          ),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<ReportTrendEntryDto> data;
  final double maxVal;
  final AppColorsExtension colors;

  LineChartPainter({
    required this.data,
    required this.maxVal,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paddingLeft = 36.0;
    final paddingBottom = 20.0;
    final paddingTop = 10.0;
    final paddingRight = 10.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    if (data.isEmpty) return;

    // Draw Grid Lines (Horizontal)
    final gridPaint = Paint()
      ..color = colors.textSecondary.withOpacity(0.06)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Grid labels and lines (3 levels)
    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight - (i / 3) * chartHeight;
      final val = (i / 3) * maxVal;

      // Draw horizontal grid line
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Draw label
      String labelText = _formatCompact(val);
      textPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    final points = <Offset>[];
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * stepX;
      final y = paddingTop + chartHeight - (data[i].expense / maxVal) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw Gradient Area below the line
    if (points.isNotEmpty) {
      final fillPath = Path();
      fillPath.moveTo(paddingLeft, paddingTop + chartHeight);
      for (var point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final gradient = LinearGradient(
        colors: [
          colors.primary.withOpacity(0.25),
          colors.primary.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw Line
    final linePaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw Dots on line
    final dotPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw dynamic labels on X-axis (Draw 5 labels max to avoid overlap)
    final labelCount = data.length < 5 ? data.length : 5;
    final labelStep = data.length > 1 ? (data.length - 1) / (labelCount - 1) : 1;

    for (int i = 0; i < labelCount; i++) {
      final index = (i * labelStep).round();
      if (index >= data.length) continue;

      final point = points[index];

      // Draw Dot
      canvas.drawCircle(point, 3.5, dotPaint);
      canvas.drawCircle(point, 3.5, dotBorderPaint);

      // Draw X Label
      textPainter.text = TextSpan(
        text: data[index].label,
        style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, paddingTop + chartHeight + 4),
      );
    }
  }

  String _formatCompact(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.maxVal != maxVal || oldDelegate.colors != colors;
}

// 📐 VẼ CUSTOM DONUT CHART PHÂN BỔ DANH MỤC TIÊU DÙNG
class ChartSegment {
  final Color color;
  final double percentage;
  ChartSegment({required this.color, required this.percentage});
}

class DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double strokeWidth;

  DonutChartPainter({required this.segments, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -3.14159 / 2; // Bắt đầu ở góc 12h

    for (var segment in segments) {
      final sweepAngle = segment.percentage * 2 * 3.14159;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}