import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/features/analytic/presentation/widgets/spending_trend_line_chart.dart';
import 'package:expense_management/features/analytic/presentation/widgets/trend_category_picker_bottom_sheet.dart';
import 'package:expense_management/features/analytic/presentation/widgets/donut_chart_painter.dart';

class StatisticsTab extends ConsumerStatefulWidget {
  const StatisticsTab({super.key});

  @override
  ConsumerState<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<StatisticsTab> {
  int? _selectedDonutIndex;
  String _categoryViewMode = 'parent'; // 'parent' or 'child'
  bool _lastSelectedFromList = false;

  bool _isLineChartExpanded = true;
  bool _isCategoriesExpanded = true;
  String _distributionMode = 'category'; // 'category' or 'wallet'
  String _categoryType = 'expense'; // 'expense' or 'income'
  String _trendLineVisibility = 'all'; // 'all', 'income', 'expense'

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
    // Reset selected segment and view mode when date range changes
    ref.listen(selectedDateRangeProvider, (previous, next) {
      if (previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedDonutIndex = null;
              _categoryViewMode = 'parent';
              _categoryType = 'expense';
              _lastSelectedFromList = false;
            });
          }
        });
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🕒 Date range filter selectors
        _buildTimeFilterBar(ref),
        const SizedBox(height: 18),

        // 💵 Balance Summary cards
        _buildSummarySection(ref),
        const SizedBox(height: 18),

        // 📈 Daily Spending Trend Line Chart (Collapsible)
        _buildLineChartSection(ref),
        const SizedBox(height: 18),

        // 🍩 Combined Categories (Collapsible)
        _buildCategoriesSection(ref),
      ],
    );
  }

  Widget _buildTimeFilterBar(WidgetRef ref) {
    final currentFilter = ref.watch(selectedTimeFilterProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);
    final colors = context.colors;

    final tzName = ref.watch(currentUserProvider.select((u) => u?.timezone)) ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);
    final now = tz.TZDateTime.now(location);

    final isCurrentMonthOrFuture = (dateRange.end.year > now.year) || 
        (dateRange.end.year == now.year && dateRange.end.month >= now.month);

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Display the selected range text
            Text(
              '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changeMonth(ref, -1),
                  color: colors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isCurrentMonthOrFuture ? null : () => _changeMonth(ref, 1),
                  color: colors.primary,
                  disabledColor: colors.textSecondary.withOpacity(0.3),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _changeMonth(WidgetRef ref, int offset) {
    final dateRange = ref.read(selectedDateRangeProvider);
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);
    
    final currentStart = dateRange.start;
    int newYear = currentStart.year;
    int newMonth = currentStart.month + offset;
    
    if (newMonth > 12) {
      newYear += 1;
      newMonth = 1;
    } else if (newMonth < 1) {
      newYear -= 1;
      newMonth = 12;
    }
    
    final now = tz.TZDateTime.now(location);
    
    if (newYear == now.year && newMonth == now.month) {
      ref.read(selectedTimeFilterProvider.notifier).state = TimeFilter.thisMonth;
      ref.read(customDateRangeProvider.notifier).state = null;
    } else {
      final startOfMonth = tz.TZDateTime(location, newYear, newMonth, 1);
      final endOfMonth = tz.TZDateTime(location, newYear, newMonth + 1, 0, 23, 59, 59);
      
      ref.read(customDateRangeProvider.notifier).state = DateTimeRange(start: startOfMonth, end: endOfMonth);
      ref.read(selectedTimeFilterProvider.notifier).state = TimeFilter.custom;
    }
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

  Widget _buildLineChartSection(WidgetRef ref) {
    final dailyTrendsAsync = ref.watch(trendsDailyProvider);
    final colors = context.colors;
    final trendType = ref.watch(selectedTrendTypeProvider);

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
          GestureDetector(
            onTap: () {
              setState(() {
                _isLineChartExpanded = !_isLineChartExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'spending_trend'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isLineChartExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
          if (_isLineChartExpanded) ...[
            const SizedBox(height: 16),
            _buildTrendFilterBar(ref),
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
              return SpendingTrendLineChart(
                data: trends,
                colors: colors,
                trendType: trendType,
                trendLineVisibility: _trendLineVisibility,
              );
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendFilterBar(WidgetRef ref) {
    final colors = context.colors;
    final selectedCategory = ref.watch(selectedTrendCategoryProvider);
    final isEnglish = ref.watch(localeProvider) == 'en';

    final categoryColor = selectedCategory != null
        ? CategoryUIConstants.getColorFromHex(selectedCategory.color, categoryName: selectedCategory.name)
        : colors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => _showTrendCategoryPicker(ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selectedCategory != null ? categoryColor.withOpacity(0.12) : colors.textSecondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedCategory != null ? categoryColor : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selectedCategory != null
                      ? CategoryUIConstants.getIconData(selectedCategory.icon, categoryName: selectedCategory.name)
                      : Icons.filter_list_rounded,
                  color: selectedCategory != null ? categoryColor : colors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    selectedCategory != null ? selectedCategory.name.tr(ref) : (isEnglish ? 'All' : 'Tất cả'),
                    style: TextStyle(
                      color: selectedCategory != null ? categoryColor : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: selectedCategory != null ? categoryColor : colors.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Income legend (Clickable)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_trendLineVisibility == 'income') {
                    _trendLineVisibility = 'all';
                  } else {
                    _trendLineVisibility = 'income';
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _trendLineVisibility == 'all' || _trendLineVisibility == 'income' ? 1.0 : 0.35,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.incomeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: colors.textSecondary.withOpacity(
                        _trendLineVisibility == 'all' || _trendLineVisibility == 'income' ? 1.0 : 0.35,
                      ),
                      fontSize: 11,
                      fontWeight: _trendLineVisibility == 'income' ? FontWeight.bold : FontWeight.w600,
                    ),
                    child: Text(isEnglish ? 'Income' : 'Thu nhập'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Expense legend (Clickable)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_trendLineVisibility == 'expense') {
                    _trendLineVisibility = 'all';
                  } else {
                    _trendLineVisibility = 'expense';
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _trendLineVisibility == 'all' || _trendLineVisibility == 'expense' ? 1.0 : 0.35,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.expenseRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: colors.textSecondary.withOpacity(
                        _trendLineVisibility == 'all' || _trendLineVisibility == 'expense' ? 1.0 : 0.35,
                      ),
                      fontSize: 11,
                      fontWeight: _trendLineVisibility == 'expense' ? FontWeight.bold : FontWeight.w600,
                    ),
                    child: Text(isEnglish ? 'Expense' : 'Chi tiêu'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTrendCategoryPicker(WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TrendCategoryPickerBottomSheet(),
    );
  }

  List<GroupedCategory> _groupCategories(List<ReportCategoryEntryDto> entries, double totalAmount) {
    final Map<String, List<ReportCategoryEntryDto>> groups = {};
    
    for (final entry in entries) {
      final key = entry.parentId ?? entry.categoryId;
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final List<GroupedCategory> groupedList = [];

    groups.forEach((parentId, childEntries) {
      ReportCategoryEntryDto? parentEntry;
      try {
        parentEntry = childEntries.firstWhere((e) => e.categoryId == parentId);
      } catch (_) {
        try {
          parentEntry = entries.firstWhere((e) => e.categoryId == parentId);
        } catch (_) {
          parentEntry = childEntries.first;
        }
      }

      final parentName = parentEntry.parentName ?? parentEntry.categoryName;
      final color = parentEntry.categoryColor ?? 'F57C00';
      final icon = parentEntry.categoryIcon;

      double totalGroupAmount = 0.0;
      for (final e in childEntries) {
        totalGroupAmount += e.amount;
      }

      childEntries.sort((a, b) => b.amount.compareTo(a.amount));

      groupedList.add(GroupedCategory(
        id: parentId,
        name: parentName,
        color: color,
        icon: icon,
        amount: totalGroupAmount,
        percentage: totalAmount > 0 ? (totalGroupAmount / totalAmount) * 100 : 0.0,
        subCategories: childEntries,
      ));
    });

    groupedList.sort((a, b) => b.amount.compareTo(a.amount));
    return groupedList;
  }



  Widget _buildCategoriesSection(WidgetRef ref) {
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';

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
          GestureDetector(
            onTap: () {
              setState(() {
                _isCategoriesExpanded = !_isCategoriesExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _categoryType == 'income'
                          ? (isEnglish ? 'Income Categories' : 'Danh mục thu nhập')
                          : 'spending_categories'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isCategoriesExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
          if (_isCategoriesExpanded) ...[
            const SizedBox(height: 16),
            _buildDistributionToggle(ref),
            const SizedBox(height: 20),
            _buildCategoryTypeToggle(ref),
            const SizedBox(height: 20),
            if (_distributionMode == 'category') ...[
              _buildDonutChartContent(ref),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 20),
              _buildTopExpensesContent(ref),
            ] else ...[
              _buildDonutChartContentForWallet(ref),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 20),
              _buildTopExpensesContentForWallet(ref),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTypeToggle(WidgetRef ref) {
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';

    return Center(
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _categoryType,
        backgroundColor: colors.textSecondary.withOpacity(0.05),
        thumbColor: colors.surface,
        children: {
          'expense': Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_down_rounded,
                  size: 14,
                  color: _categoryType == 'expense' ? colors.expenseRed : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isEnglish ? 'Expense' : 'Chi tiêu',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _categoryType == 'expense' ? colors.expenseRed : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          'income': Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: _categoryType == 'income' ? colors.incomeGreen : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isEnglish ? 'Income' : 'Thu nhập',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _categoryType == 'income' ? colors.incomeGreen : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _categoryType = value;
              _selectedDonutIndex = null;
              _lastSelectedFromList = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildDistributionToggle(WidgetRef ref) {
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';

    final byCategoryLabel = isEnglish ? 'By Category' : 'Theo danh mục';
    final byWalletLabel = isEnglish ? 'By Wallet/Account' : 'Theo ví / tài khoản';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.textSecondary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(
              isSelected: _distributionMode == 'category',
              label: byCategoryLabel,
              icon: Icons.folder_copy_rounded,
              onTap: () {
                setState(() {
                  _distributionMode = 'category';
                  _selectedDonutIndex = null;
                  _lastSelectedFromList = false;
                });
              },
              colors: colors,
            ),
            const SizedBox(width: 4),
            _buildToggleButton(
              isSelected: _distributionMode == 'wallet',
              label: byWalletLabel,
              icon: Icons.account_balance_wallet_rounded,
              onTap: () {
                setState(() {
                  _distributionMode = 'wallet';
                  _selectedDonutIndex = null;
                  _lastSelectedFromList = false;
                });
              },
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required bool isSelected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [colors.primary, colors.primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChartContentForWallet(WidgetRef ref) {
    final walletsAsync = ref.watch(reportWalletsProvider(_categoryType));
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wallet_distribution'.tr(ref) == 'wallet_distribution' ? 'Phân bổ theo ví' : 'wallet_distribution'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        () {
          final reportData = walletsAsync.asData?.value;
          if (reportData == null) {
            if (walletsAsync.isLoading) {
              return _buildShimmerCard(height: 160);
            }
            return SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  walletsAsync.error != null
                      ? 'error_with_details'.tr(ref).replaceAll('{error}', walletsAsync.error.toString())
                      : 'no_data'.tr(ref),
                  style: TextStyle(color: colors.expenseRed),
                ),
              ),
            );
          }

          final entries = reportData.wallets;
          if (entries.isEmpty) {
            return SizedBox(
              height: 160,
              child: Center(
                child: Text('no_spending_this_period'.tr(ref)),
              ),
            );
          }

          final selectedIndex = (_selectedDonutIndex != null &&
                  _selectedDonutIndex! < entries.length)
              ? _selectedDonutIndex
              : null;

          final walletEntry = selectedIndex != null ? entries[selectedIndex] : null;

          final List<ChartSegment> segments;
          const double minVisualPercentage = 0.02; // Enforce a 2% minimum visual slice size

          final rawPercentages = entries.map((e) => reportData.totalAmount > 0 ? (e.amount / reportData.totalAmount) : 0.0).toList();
          double totalAdjusted = 0.0;
          final adjusted = <double>[];
          for (final p in rawPercentages) {
            final adj = p > 0 ? (p < minVisualPercentage ? minVisualPercentage : p) : 0.0;
            adjusted.add(adj);
            totalAdjusted += adj;
          }
          segments = List.generate(entries.length, (i) {
            final e = entries[i];
            final walletColor = CategoryUIConstants.getColorFromHex(e.walletColor);
            final normPercentage = totalAdjusted > 0 ? (adjusted[i] / totalAdjusted) : 0.0;
            return ChartSegment(
              color: walletColor,
              percentage: normPercentage,
            );
          });

          return Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final x = details.localPosition.dx;
                  final y = details.localPosition.dy;
                  
                  const centerX = 80.0;
                  const centerY = 80.0;
                  
                  final dx = x - centerX;
                  final dy = y - centerY;
                  final distance = sqrt(dx * dx + dy * dy);
                  
                  if (distance < 40) {
                    setState(() {
                      _selectedDonutIndex = null;
                      _lastSelectedFromList = false;
                    });
                  } else if (distance >= 40 && distance <= 85) {
                    double angle = atan2(dy, dx);
                    double normalizedAngle = angle + pi / 2;
                    if (normalizedAngle < 0) {
                      normalizedAngle += 2 * pi;
                    }
                    
                    double currentAngle = 0.0;
                    for (int i = 0; i < segments.length; i++) {
                      final sweepAngle = segments[i].percentage * 2 * pi;
                      if (normalizedAngle >= currentAngle && normalizedAngle <= currentAngle + sweepAngle) {
                        setState(() {
                          _selectedDonutIndex = (_selectedDonutIndex == i) ? null : i;
                          _lastSelectedFromList = false;
                        });
                        break;
                      }
                      currentAngle += sweepAngle;
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: CustomPaint(
                        size: const Size(150, 150),
                        painter: DonutChartPainter(
                          segments: segments,
                          strokeWidth: 20,
                          selectedIndex: _selectedDonutIndex,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (selectedIndex == null) ...[
                              Text(
                                _categoryType == 'income' ? 'Tổng thu' : 'Tổng chi',
                                style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatCompactCurrency(reportData.totalAmount),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              Text(
                                walletEntry!.walletName,
                                style: TextStyle(
                                  color: CategoryUIConstants.getColorFromHex(walletEntry.walletColor),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _formatCompactCurrency(walletEntry.amount),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${walletEntry.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildTopExpensesContentForWallet(WidgetRef ref) {
    final walletsAsync = ref.watch(reportWalletsProvider(_categoryType));
    final colors = context.colors;

    return () {
      final reportData = walletsAsync.asData?.value;
      if (reportData == null) {
        if (walletsAsync.isLoading) {
          return _buildShimmerCard(height: 200);
        }
        return Center(
          child: Text(
            walletsAsync.error != null
                ? 'error_with_details'.tr(ref).replaceAll('{error}', walletsAsync.error.toString())
                : 'no_data'.tr(ref),
            style: TextStyle(color: colors.expenseRed, fontSize: 13),
          ),
        );
      }

      final entries = reportData.wallets;
      if (entries.isEmpty) {
        return Center(
          child: Text(
            'no_spending_data'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        );
      }

      final selectedIndex = (_selectedDonutIndex != null && _selectedDonutIndex! < entries.length)
          ? _selectedDonutIndex
          : null;

      return Column(
        children: List.generate(entries.length, (index) {
          final e = entries[index];
          final progressColor = CategoryUIConstants.getColorFromHex(e.walletColor);
          final isSelected = selectedIndex == index;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isSelected) {
                if (_lastSelectedFromList) {
                  final range = ref.read(selectedDateRangeProvider);
                  ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
                    walletId: e.walletId,
                    startDate: range.start.toUtc().toIso8601String(),
                    endDate: range.end.toUtc().toIso8601String(),
                    type: _categoryType,
                  );
                  context.go(RoutePaths.history);
                } else {
                  setState(() {
                    _lastSelectedFromList = true;
                  });
                }
              } else {
                setState(() {
                  _selectedDonutIndex = index;
                  _lastSelectedFromList = true;
                });
              }
            },
            child: _buildWalletExpenseRow(
              e.walletName,
              _formatCurrency(e.amount),
              reportData.totalAmount > 0 ? (e.amount / reportData.totalAmount) : 0.0,
              progressColor,
              e.walletIcon,
              colors,
              isSelected: isSelected,
            ),
          );
        }),
      );
    }();
  }

  Widget _buildWalletExpenseRow(
    String title,
    String amount,
    double pct,
    Color progressColor,
    String walletIconKey,
    AppColorsExtension colors, {
    bool isSelected = false,
  }) {
    IconData iconData;
    final iconKey = walletIconKey.toLowerCase();
    if (iconKey.contains('cash') || iconKey.contains('payment')) {
      iconData = Icons.payments_rounded;
    } else if (iconKey.contains('bank') || iconKey.contains('balance')) {
      iconData = Icons.account_balance_rounded;
    } else {
      iconData = Icons.credit_card_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isSelected ? progressColor.withOpacity(0.08) : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? progressColor.withOpacity(0.3) : colors.textSecondary.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chiếm ${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: isSelected ? progressColor : colors.textSecondary.withOpacity(0.3),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: colors.textSecondary.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartContent(WidgetRef ref) {
    final categoriesAsync = ref.watch(
      _categoryType == 'income' ? reportIncomeCategoriesProvider : reportCategoriesProvider,
    );
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _categoryType == 'income'
                  ? (isEnglish ? 'Income Distribution' : 'Phân bổ thu nhập')
                  : 'category_distribution'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _categoryViewMode,
              backgroundColor: colors.textSecondary.withOpacity(0.05),
              thumbColor: colors.surface,
              children: {
                'parent': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    isEnglish ? 'Parent' : 'Cha',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _categoryViewMode == 'parent' ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
                'child': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    isEnglish ? 'Child' : 'Con',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _categoryViewMode == 'child' ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    _categoryViewMode = value;
                    _selectedDonutIndex = null;
                    _lastSelectedFromList = false;
                  });
                }
              },
            ),
          ],
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
                child: Text(
                  _categoryType == 'income'
                      ? (isEnglish ? 'No income in this period' : 'Chưa có thu nhập trong kỳ này')
                      : 'no_spending_this_period'.tr(ref),
                ),
              ),
            );
          }

          final groupedList = _groupCategories(entries, reportData.totalAmount);
          final childList = List<ReportCategoryEntryDto>.from(entries)..sort((a, b) => b.amount.compareTo(a.amount));
          final isChildMode = _categoryViewMode == 'child';

          final selectedIndex = (_selectedDonutIndex != null &&
                  _selectedDonutIndex! < (isChildMode ? childList.length : groupedList.length))
              ? _selectedDonutIndex
              : null;

          final group = (!isChildMode && selectedIndex != null) ? groupedList[selectedIndex] : null;
          final childEntry = (isChildMode && selectedIndex != null) ? childList[selectedIndex] : null;

          final List<ChartSegment> segments;
          const double minVisualPercentage = 0.02; // Enforce a 2% minimum visual slice size

          if (isChildMode) {
            final rawPercentages = childList.map((e) => reportData.totalAmount > 0 ? (e.amount / reportData.totalAmount) : 0.0).toList();
            double totalAdjusted = 0.0;
            final adjusted = <double>[];
            for (final p in rawPercentages) {
              final adj = p > 0 ? (p < minVisualPercentage ? minVisualPercentage : p) : 0.0;
              adjusted.add(adj);
              totalAdjusted += adj;
            }
            segments = List.generate(childList.length, (i) {
              final e = childList[i];
              final categoryColor = CategoryUIConstants.getColorFromHex(e.categoryColor);
              final normPercentage = totalAdjusted > 0 ? (adjusted[i] / totalAdjusted) : 0.0;
              return ChartSegment(
                color: categoryColor,
                percentage: normPercentage,
              );
            });
          } else {
            final rawPercentages = groupedList.map((g) => g.percentage / 100.0).toList();
            double totalAdjusted = 0.0;
            final adjusted = <double>[];
            for (final p in rawPercentages) {
              final adj = p > 0 ? (p < minVisualPercentage ? minVisualPercentage : p) : 0.0;
              adjusted.add(adj);
              totalAdjusted += adj;
            }
            segments = List.generate(groupedList.length, (i) {
              final g = groupedList[i];
              final categoryColor = CategoryUIConstants.getColorFromHex(g.color);
              final normPercentage = totalAdjusted > 0 ? (adjusted[i] / totalAdjusted) : 0.0;
              return ChartSegment(
                color: categoryColor,
                percentage: normPercentage,
              );
            });
          }

          return Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final x = details.localPosition.dx;
                  final y = details.localPosition.dy;
                  
                  const centerX = 80.0;
                  const centerY = 80.0;
                  
                  final dx = x - centerX;
                  final dy = y - centerY;
                  final distance = sqrt(dx * dx + dy * dy);
                  
                  if (distance < 40) {
                    setState(() {
                      _selectedDonutIndex = null;
                      _lastSelectedFromList = false;
                    });
                  } else if (distance >= 40 && distance <= 85) {
                    double angle = atan2(dy, dx);
                    double normalizedAngle = angle + pi / 2;
                    if (normalizedAngle < 0) {
                      normalizedAngle += 2 * pi;
                    }
                    
                    double currentAngle = 0.0;
                    for (int i = 0; i < segments.length; i++) {
                      final sweepAngle = segments[i].percentage * 2 * pi;
                      if (normalizedAngle >= currentAngle && normalizedAngle <= currentAngle + sweepAngle) {
                        setState(() {
                          _selectedDonutIndex = (_selectedDonutIndex == i) ? null : i;
                          _lastSelectedFromList = false;
                        });
                        break;
                      }
                      currentAngle += sweepAngle;
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: CustomPaint(
                        size: const Size(150, 150),
                        painter: DonutChartPainter(
                          segments: segments,
                          strokeWidth: 20,
                          selectedIndex: _selectedDonutIndex,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (selectedIndex == null) ...[
                              Text(
                                _categoryType == 'income' ? 'total_income'.tr(ref) : 'total_expense'.tr(ref),
                                style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatCompactCurrency(reportData.totalAmount),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              if (!isChildMode) ...[
                                Text(
                                  group!.name.tr(ref),
                                  style: TextStyle(
                                    color: CategoryUIConstants.getColorFromHex(group.color),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _formatCompactCurrency(group.amount),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${group.percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                Text(
                                  childEntry!.categoryName.tr(ref),
                                  style: TextStyle(
                                    color: CategoryUIConstants.getColorFromHex(childEntry.categoryColor),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _formatCompactCurrency(childEntry.amount),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${(reportData.totalAmount > 0 ? (childEntry.amount / reportData.totalAmount) * 100 : 0.0).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildTopExpensesContent(WidgetRef ref) {
    final categoriesAsync = ref.watch(
      _categoryType == 'income' ? reportIncomeCategoriesProvider : reportCategoriesProvider,
    );
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';

    return () {
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
            _categoryType == 'income'
                ? (isEnglish ? 'No income data' : 'Chưa có dữ liệu thu nhập')
                : 'no_spending_data'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        );
      }

      final isChildMode = _categoryViewMode == 'child';

      if (isChildMode) {
        final childList = List<ReportCategoryEntryDto>.from(entries)..sort((a, b) => b.amount.compareTo(a.amount));
        final selectedIndex = (_selectedDonutIndex != null && _selectedDonutIndex! < childList.length)
            ? _selectedDonutIndex
            : null;

        return Column(
          children: List.generate(childList.length, (index) {
            final e = childList[index];
            final progressColor = CategoryUIConstants.getColorFromHex(e.categoryColor);
            final isSelected = selectedIndex == index;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isSelected) {
                  if (_lastSelectedFromList) {
                    final range = ref.read(selectedDateRangeProvider);
                    final timeFilter = ref.read(selectedTimeFilterProvider);
                    String timeMode = 'month';
                    if (timeFilter == TimeFilter.thisWeek) timeMode = 'week';
                    if (timeFilter == TimeFilter.thisYear) timeMode = 'year';

                    context.push(RoutePaths.categoryDetail, extra: {
                      'categoryId': e.categoryId,
                      'categoryName': e.categoryName,
                      'categoryColor': e.categoryColor,
                      'categoryIcon': e.categoryIcon,
                      'type': _categoryType,
                      'startDate': range.start,
                      'endDate': range.end,
                      'timeMode': timeMode,
                    });
                  } else {
                    setState(() {
                      _lastSelectedFromList = true;
                    });
                  }
                } else {
                  setState(() {
                    _selectedDonutIndex = index;
                    _lastSelectedFromList = true;
                  });
                }
              },
              child: _buildTopExpenseRow(
                e.categoryName.tr(ref),
                _formatCurrency(e.amount),
                reportData.totalAmount > 0 ? (e.amount / reportData.totalAmount) : 0.0,
                progressColor,
                colors,
                isSelected: isSelected,
              ),
            );
          }),
        );
      } else {
        final groupedList = _groupCategories(entries, reportData.totalAmount);
        final selectedIndex = (_selectedDonutIndex != null && _selectedDonutIndex! < groupedList.length)
            ? _selectedDonutIndex
            : null;

        return Column(
          children: List.generate(groupedList.length, (index) {
            final g = groupedList[index];
            final progressColor = CategoryUIConstants.getColorFromHex(g.color);
            final isSelected = selectedIndex == index;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isSelected) {
                  if (_lastSelectedFromList) {
                    final range = ref.read(selectedDateRangeProvider);
                    final timeFilter = ref.read(selectedTimeFilterProvider);
                    String timeMode = 'month';
                    if (timeFilter == TimeFilter.thisWeek) timeMode = 'week';
                    if (timeFilter == TimeFilter.thisYear) timeMode = 'year';

                    context.push(RoutePaths.categoryDetail, extra: {
                      'categoryId': g.id,
                      'categoryName': g.name,
                      'categoryColor': g.color,
                      'categoryIcon': g.icon,
                      'type': _categoryType,
                      'startDate': range.start,
                      'endDate': range.end,
                      'timeMode': timeMode,
                    });
                  } else {
                    setState(() {
                      _lastSelectedFromList = true;
                    });
                  }
                } else {
                  setState(() {
                    _selectedDonutIndex = index;
                    _lastSelectedFromList = true;
                  });
                }
              },
              child: _buildTopExpenseRow(
                g.name.tr(ref),
                _formatCurrency(g.amount),
                g.percentage / 100.0,
                progressColor,
                colors,
                isSelected: isSelected,
              ),
            );
          }),
        );
      }
    }();
  }

  Widget _buildTopExpenseRow(
    String title,
    String amount,
    double pct,
    Color progressColor,
    AppColorsExtension colors, {
    bool isSelected = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isSelected ? progressColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? progressColor.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
                    backgroundColor: isSelected
                        ? progressColor.withOpacity(0.2)
                        : colors.textSecondary.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: isSelected ? progressColor : colors.textSecondary.withOpacity(0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}



