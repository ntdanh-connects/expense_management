import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import '../spending_trend_line_chart.dart';
import '../trend_category_picker_bottom_sheet.dart';

class StatisticsTrendChartSection extends ConsumerStatefulWidget {
  const StatisticsTrendChartSection({super.key});

  @override
  ConsumerState<StatisticsTrendChartSection> createState() =>
      _StatisticsTrendChartSectionState();
}

class _StatisticsTrendChartSectionState
    extends ConsumerState<StatisticsTrendChartSection> {
  bool _isLineChartExpanded = true;
  String _trendLineVisibility = 'all'; // 'all', 'income', 'expense'

  Widget _buildShimmerCard(double height) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withValues(alpha: 0.08),
      highlightColor: colors.textSecondary.withValues(alpha: 0.03),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dailyTrendsAsync = ref.watch(trendsDailyProvider);
    final trendType = ref.watch(selectedTrendTypeProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.05)),
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
              final trends = dailyTrendsAsync.value;
              if (trends == null) {
                if (dailyTrendsAsync.isLoading) {
                  return _buildShimmerCard(160);
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
          onTap: () => _showTrendCategoryPicker(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selectedCategory != null
                  ? categoryColor.withValues(alpha: 0.12)
                  : colors.textSecondary.withValues(alpha: 0.05),
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
            // Income legend
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
                      color: colors.textSecondary.withValues(
                        alpha: _trendLineVisibility == 'all' || _trendLineVisibility == 'income' ? 1.0 : 0.35,
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
            // Expense legend
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
                      color: colors.textSecondary.withValues(
                        alpha: _trendLineVisibility == 'all' || _trendLineVisibility == 'expense' ? 1.0 : 0.35,
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

  void _showTrendCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TrendCategoryPickerBottomSheet(),
    );
  }
}
