import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';

class FluctuationBreakdownSection extends ConsumerStatefulWidget {
  final DateTimeRange periodRange;
  final double totalPeriodAmount;
  final List<ReportTrendEntryDto> trends;
  final int selectedPeriodIndex;
  final ValueChanged<int> onPeriodSelected;
  final String timeMode;
  final String typeMode;
  final bool isCompareEnabled;

  const FluctuationBreakdownSection({
    super.key,
    required this.periodRange,
    required this.totalPeriodAmount,
    required this.trends,
    required this.selectedPeriodIndex,
    required this.onPeriodSelected,
    required this.timeMode,
    required this.typeMode,
    required this.isCompareEnabled,
  });

  @override
  ConsumerState<FluctuationBreakdownSection> createState() =>
      _FluctuationBreakdownSectionState();
}

class _FluctuationBreakdownSectionState
    extends ConsumerState<FluctuationBreakdownSection> {
  String _categoryMode = 'child'; // 'child', 'parent'

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  String _formatCompact(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M đ';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K đ';
    }
    return '${val.toStringAsFixed(0)}đ';
  }

  DateTimeRange _getPeriodRange(ReportTrendEntryDto trend, String mode) {
    final dateStr = trend.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final trendDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    if (mode == 'week') {
      final start = DateTime(trendDate.year, trendDate.month, trendDate.day);
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      return DateTimeRange(start: start, end: end);
    } else if (mode == 'month') {
      final start = DateTime(trendDate.year, trendDate.month, 1);
      final end = DateTime(trendDate.year, trendDate.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    } else {
      final year = trend.year ?? trendDate.year;
      return DateTimeRange(
        start: DateTime(year, 1, 1),
        end: DateTime(year, 12, 31, 23, 59, 59),
      );
    }
  }

  Widget _buildShimmerBreakdown(AppColorsExtension colors) {
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withOpacity(0.08),
      highlightColor: colors.textSecondary.withOpacity(0.03),
      child: Column(
        children: List.generate(4, (index) => Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ),
    );
  }

  List<CategoryUIItem> _groupCategoriesToUI(List<ReportCategoryEntryDto> entries, double totalAmount) {
    final Map<String, List<ReportCategoryEntryDto>> groups = {};
    for (final entry in entries) {
      final key = entry.parentId ?? entry.categoryId;
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final List<CategoryUIItem> groupedList = [];
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
      final color = parentEntry.categoryColor ?? 'FFC68C';
      final icon = parentEntry.categoryIcon;

      double totalGroupAmount = 0.0;
      for (final e in childEntries) {
        totalGroupAmount += e.amount;
      }

      groupedList.add(CategoryUIItem(
        id: parentId,
        name: parentName,
        color: color,
        icon: icon,
        amount: totalGroupAmount,
        percentage: totalAmount > 0 ? (totalGroupAmount / totalAmount) * 100 : 0.0,
      ));
    });
    return groupedList;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (widget.typeMode == 'difference') {
      return _buildNetDifferenceList(widget.trends, colors);
    }

    // Fetch current categories
    final categoriesAsync = ref.watch(categoriesByPeriodProvider((
      startDate: widget.periodRange.start,
      endDate: widget.periodRange.end,
      type: widget.typeMode,
    )));

    // Fetch previous period categories if selected index > 0 to compute changes
    AsyncValue<ReportCategoryDto>? prevCategoriesAsync;
    if (widget.selectedPeriodIndex > 0) {
      final prevTrend = widget.trends[widget.selectedPeriodIndex - 1];
      final prevRange = _getPeriodRange(prevTrend, widget.timeMode);
      prevCategoriesAsync = ref.watch(categoriesByPeriodProvider((
        startDate: prevRange.start,
        endDate: prevRange.end,
        type: widget.typeMode,
      )));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.typeMode == 'expense') ...[
          _buildParentChildSegments(colors),
          const SizedBox(height: 18),
        ],

        categoriesAsync.when(
          data: (reportData) {
            final entries = reportData.categories;
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Không có dữ liệu trong kỳ này',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              );
            }

            List<CategoryUIItem> uiItems = [];
            if (widget.typeMode == 'expense' && _categoryMode == 'parent') {
              uiItems = _groupCategoriesToUI(entries, widget.totalPeriodAmount);
            } else {
              uiItems = entries
                  .map((e) => CategoryUIItem(
                        id: e.categoryId,
                        name: e.categoryName,
                        color: e.categoryColor ?? '9BFFE5',
                        icon: e.categoryIcon,
                        amount: e.amount,
                        percentage: widget.totalPeriodAmount > 0 ? (e.amount / widget.totalPeriodAmount) * 100 : 0.0,
                      ))
                  .toList();
            }

            uiItems.sort((a, b) => b.amount.compareTo(a.amount));

            final prevData = prevCategoriesAsync?.value;
            final Map<String, double> prevAmounts = {};
            if (prevData != null) {
              if (widget.typeMode == 'expense' && _categoryMode == 'parent') {
                final groupedPrev = _groupCategoriesToUI(prevData.categories, prevData.totalAmount);
                for (final g in groupedPrev) {
                  prevAmounts[g.name] = g.amount;
                }
              } else {
                for (final c in prevData.categories) {
                  prevAmounts[c.categoryName] = c.amount;
                }
              }
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uiItems.length,
              separatorBuilder: (context, index) => const Divider(height: 20, thickness: 0.5),
              itemBuilder: (context, index) {
                final item = uiItems[index];
                final catColor = CategoryUIConstants.getColorFromHex(item.color);
                final catIcon = CategoryUIConstants.getIconData(item.icon);

                double diff = 0.0;
                bool showDiff = widget.isCompareEnabled && widget.selectedPeriodIndex > 0;
                if (showDiff) {
                  final prevAmt = prevAmounts[item.name] ?? 0.0;
                  diff = item.amount - prevAmt;
                }

                return InkWell(
                  onTap: () {
                    context.push(
                      RoutePaths.categoryDetail,
                      extra: {
                        'categoryId': item.id,
                        'categoryName': item.name,
                        'categoryColor': item.color,
                        'categoryIcon': item.icon,
                        'type': widget.typeMode,
                        'startDate': widget.periodRange.start,
                        'endDate': widget.periodRange.end,
                        'timeMode': widget.timeMode,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: catColor.withOpacity(0.12),
                          radius: 20,
                          child: Icon(catIcon, color: catColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatCurrency(item.amount),
                                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.textSecondary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (showDiff) ...[
                                        const SizedBox(width: 6),
                                        _buildDiffIndicatorText(diff, colors),
                                      ],
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary.withOpacity(0.5), size: 12),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => _buildShimmerBreakdown(colors),
          error: (err, _) => Text('Lỗi breakdown: $err', style: TextStyle(color: colors.expenseRed)),
        ),
      ],
    );
  }

  Widget _buildDiffIndicatorText(double diff, AppColorsExtension colors) {
    if (diff > 0) {
      return Text(
        'Tăng ${_formatCompact(diff)}',
        style: TextStyle(color: colors.expenseRed, fontSize: 11, fontWeight: FontWeight.w500),
      );
    } else if (diff < 0) {
      return Text(
        'Giảm ${_formatCompact(-diff)}',
        style: TextStyle(color: colors.incomeGreen, fontSize: 11, fontWeight: FontWeight.w500),
      );
    } else {
      return Text(
        'Không đổi',
        style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
      );
    }
  }

  Widget _buildParentChildSegments(AppColorsExtension colors) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _categoryMode,
        backgroundColor: colors.textSecondary.withOpacity(0.05),
        thumbColor: Colors.white,
        children: {
          'child': Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Danh mục con',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: _categoryMode == 'child' ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
          'parent': Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Danh mục cha',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: _categoryMode == 'parent' ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
        },
        onValueChanged: (val) {
          if (val != null) {
            setState(() {
              _categoryMode = val;
            });
          }
        },
      ),
    );
  }

  Widget _buildNetDifferenceList(List<ReportTrendEntryDto> trends, AppColorsExtension colors) {
    final reversedTrends = List<ReportTrendEntryDto>.from(trends.reversed);
    final isEnglish = ref.watch(localeProvider) == 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử chênh lệch thu chi',
          style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversedTrends.length,
          separatorBuilder: (context, index) => const Divider(height: 20, thickness: 0.5),
          itemBuilder: (context, index) {
            final trend = reversedTrends[index];
            final originalIndex = trends.indexOf(trend);
            final isSelected = originalIndex == widget.selectedPeriodIndex;
            final net = trend.income - trend.expense;

            return InkWell(
              onTap: () => widget.onPeriodSelected(originalIndex),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? colors.primary.withOpacity(0.3) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildDateBadge(trend, colors, isEnglish),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thu ${_formatCompact(trend.income)}',
                            style: TextStyle(
                              color: colors.textSecondary, 
                              fontSize: 12.5, 
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chi ${_formatCompact(trend.expense)}',
                            style: TextStyle(
                              color: colors.textSecondary, 
                              fontSize: 12.5, 
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Còn lại',
                          style: TextStyle(color: colors.textSecondary, fontSize: 10.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (net > 0 ? '+' : '') + _formatCurrency(net),
                          style: TextStyle(
                            color: net > 0 
                                ? colors.incomeGreen 
                                : (net < 0 ? colors.expenseRed : colors.primary),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateBadge(ReportTrendEntryDto trend, AppColorsExtension colors, bool isEnglish) {
    final dateStr = trend.date ?? '';
    final startDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    if (widget.timeMode == 'week') {
      final endDate = startDate.add(const Duration(days: 6));
      return Container(
        width: 76,
        height: 52,
        decoration: BoxDecoration(
          color: colors.textSecondary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${startDate.day.toString().padLeft(2, '0')} - ${endDate.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isEnglish 
                  ? 'Month ${startDate.month.toString().padLeft(2, '0')}' 
                  : 'Tháng ${startDate.month.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (widget.timeMode == 'month') {
      return Container(
        width: 76,
        height: 52,
        decoration: BoxDecoration(
          color: colors.textSecondary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${trend.month ?? startDate.month}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${trend.year ?? startDate.year}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: 76,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.textSecondary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${trend.year ?? startDate.year}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}

class CategoryUIItem {
  final String id;
  final String name;
  final String color;
  final String? icon;
  final double amount;
  final double percentage;

  CategoryUIItem({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.amount,
    required this.percentage,
  });
}
