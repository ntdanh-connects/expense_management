import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';

import '../widgets/category_detail/category_detail_header.dart';
import '../widgets/category_detail/category_detail_chart.dart';
import '../widgets/category_detail/category_detail_stats_grid.dart';
import '../widgets/category_detail/category_subcategory_breakdown.dart';
import '../widgets/category_detail/category_suggestion_section.dart';
import '../widgets/category_detail/category_detail_tx_list.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final String type; // 'income' or 'expense'
  final DateTime startDate;
  final DateTime endDate;
  final String timeMode; // 'week', 'month', 'year'

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.timeMode,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late String _currentCategoryId;
  late String _currentCategoryName;
  late String? _currentCategoryColor;
  late String? _currentCategoryIcon;

  int _selectedChartIndex = 5;
  bool _isAmountVisible = true;
  String? _selectedSubcategoryFilter;

  @override
  void initState() {
    super.initState();
    _currentCategoryId = widget.categoryId;
    _currentCategoryName = widget.categoryName;
    _currentCategoryColor = widget.categoryColor;
    _currentCategoryIcon = widget.categoryIcon;
    _selectedChartIndex = (widget.timeMode == 'year') ? 1 : 5;
  }

  DateTime _getChartStartDate() {
    final endDate = widget.endDate;
    if (endDate is tz.TZDateTime) {
      final loc = endDate.location;
      if (widget.timeMode == 'week') {
        final start = endDate.subtract(const Duration(days: 41));
        return tz.TZDateTime(loc, start.year, start.month, start.day);
      } else if (widget.timeMode == 'month') {
        return tz.TZDateTime(loc, endDate.year, endDate.month - 5, 1);
      } else {
        return tz.TZDateTime(loc, endDate.year - 1, 1, 1);
      }
    } else {
      if (widget.timeMode == 'week') {
        return endDate.subtract(const Duration(days: 41));
      } else if (widget.timeMode == 'month') {
        return DateTime(endDate.year, endDate.month - 5, 1);
      } else {
        return DateTime(endDate.year - 1, 1, 1);
      }
    }
  }

  List<PeriodBucket> _generatePeriods(DateTime start, DateTime end, String mode) {
    final List<PeriodBucket> buckets = [];
    if (mode == 'week') {
      for (int i = 0; i < 6; i++) {
        final wStart = start.add(Duration(days: i * 7));
        final wEnd = wStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        buckets.add(PeriodBucket(start: wStart, end: wEnd, label: '${wStart.day}/${wStart.month}'));
      }
    } else if (mode == 'month') {
      for (int i = 0; i < 6; i++) {
        final date = DateTime(start.year, start.month + i, 1);
        final mStart = DateTime(date.year, date.month, 1);
        final mEnd = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        buckets.add(PeriodBucket(
          start: mStart,
          end: mEnd,
          label: i == 0 ? '${mStart.month}/${mStart.year}' : '${mStart.month}',
        ));
      }
    } else {
      for (int i = 0; i < 2; i++) {
        final year = start.year + i;
        buckets.add(PeriodBucket(start: DateTime(year, 1, 1), end: DateTime(year, 12, 31, 23, 59, 59), label: '$year'));
      }
    }
    return buckets;
  }

  String _getPeriodLabel(DateTime start, String mode) {
    if (mode == 'week') {
      final end = start.add(const Duration(days: 6));
      return 'Tuần ${start.day}/${start.month} - ${end.day}/${end.month}';
    } else if (mode == 'month') {
      return 'Tháng ${start.month}/${start.year}';
    } else {
      return 'Năm ${start.year}';
    }
  }

  Widget _buildShimmerHeader(AppColorsExtension colors) {
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withOpacity(0.08),
      highlightColor: colors.textSecondary.withOpacity(0.03),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildShimmerCard({required double height, required AppColorsExtension colors}) {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tzName = ref.watch(currentUserProvider.select((u) => u?.timezone)) ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);

    final chartStartDate = _getChartStartDate();
    final chartEndDate = widget.endDate;

    final txAsync = ref.watch(
      categoryDetailTransactionsProvider((
        categoryId: _currentCategoryId,
        startDate: chartStartDate,
        endDate: chartEndDate,
        type: widget.type,
      )),
    );

    return Scaffold(
      backgroundColor: isDark ? colors.background : const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _currentCategoryName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: txAsync.when(
        data: (transactions) {
          final periods = _generatePeriods(chartStartDate, chartEndDate, widget.timeMode);

          final List<double> periodAmounts = List.filled(periods.length, 0.0);
          for (final tx in transactions) {
            final txDate = tz.TZDateTime.from(tx.transactionDate, location);
            for (int i = 0; i < periods.length; i++) {
              if (txDate.isAfter(periods[i].start.subtract(const Duration(seconds: 1))) &&
                  txDate.isBefore(periods[i].end.add(const Duration(seconds: 1)))) {
                periodAmounts[i] += tx.amountInUserCurrency;
                break;
              }
            }
          }

          if (_selectedChartIndex >= periods.length) {
            _selectedChartIndex = periods.length - 1;
          }

          final currentPeriod = periods[_selectedChartIndex];
          final currentPeriodAmount = periodAmounts[_selectedChartIndex];

          final nonZeroAmounts = periodAmounts.where((amt) => amt > 0).toList();
          final double averageAmount = nonZeroAmounts.isEmpty
              ? 0
              : nonZeroAmounts.reduce((a, b) => a + b) / nonZeroAmounts.length;

          final selectedPeriodTxs = transactions.where((tx) {
            final txDate = tz.TZDateTime.from(tx.transactionDate, location);
            return txDate.isAfter(currentPeriod.start.subtract(const Duration(seconds: 1))) &&
                txDate.isBefore(currentPeriod.end.add(const Duration(seconds: 1)));
          }).toList();

          double? percentageChange;
          if (_selectedChartIndex > 0) {
            final prevPeriodAmount = periodAmounts[_selectedChartIndex - 1];
            if (prevPeriodAmount > 0) {
              percentageChange = ((currentPeriodAmount - prevPeriodAmount) / prevPeriodAmount) * 100;
            } else if (currentPeriodAmount > 0) {
              percentageChange = 100.0;
            }
          }

          final displayTxs = _selectedSubcategoryFilter == null
              ? selectedPeriodTxs
              : selectedPeriodTxs.where((tx) => (tx.categoryName ?? 'Chưa phân loại') == _selectedSubcategoryFilter).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🪙 1. Header Statistics Block
                CategoryDetailHeader(
                  periodLabel: _getPeriodLabel(currentPeriod.start, widget.timeMode),
                  type: widget.type,
                  currentPeriodAmount: currentPeriodAmount,
                  averageAmount: averageAmount,
                  isAmountVisible: _isAmountVisible,
                  onAmountVisibilityChanged: (val) {
                    setState(() {
                      _isAmountVisible = val;
                    });
                  },
                ),

                // 📊 2. Custom Column Chart Section
                CategoryDetailChart(
                  periods: periods,
                  periodAmounts: periodAmounts,
                  selectedChartIndex: _selectedChartIndex,
                  onChartIndexChanged: (idx) {
                    setState(() {
                      _selectedChartIndex = idx;
                      _selectedSubcategoryFilter = null;
                    });
                  },
                  averageAmount: averageAmount,
                  timeMode: widget.timeMode,
                ),

                // 📊 3. Detailed Statistics Section (Grid)
                CategoryDetailStatsGrid(
                  type: widget.type,
                  selectedPeriodTxs: selectedPeriodTxs,
                  currentPeriodAmount: currentPeriodAmount,
                  percentageChange: percentageChange,
                ),

                // 🍕 4. Subcategory Breakdown Section
                CategorySubcategoryBreakdown(
                  selectedPeriodTxs: selectedPeriodTxs,
                  currentPeriodAmount: currentPeriodAmount,
                  selectedSubcategoryFilter: _selectedSubcategoryFilter,
                  onSubcategoryFilterChanged: (val) {
                    setState(() {
                      _selectedSubcategoryFilter = val;
                    });
                  },
                  categoryColor: _currentCategoryColor,
                  categoryIcon: _currentCategoryIcon,
                ),

                // 💡 5. Suggestion Card Section
                if (widget.type == 'expense')
                  CategorySuggestionSection(categoryName: _currentCategoryName),

                // 💸 6. Transactions List Section
                CategoryDetailTxList(
                  displayTxs: displayTxs,
                  type: widget.type,
                  selectedSubcategoryFilter: _selectedSubcategoryFilter,
                  onClearSubcategoryFilter: () {
                    setState(() {
                      _selectedSubcategoryFilter = null;
                    });
                  },
                  categoryColor: _currentCategoryColor,
                  categoryIcon: _currentCategoryIcon,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => Column(
          children: [
            _buildShimmerHeader(colors),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildShimmerCard(height: 200, colors: colors),
            ),
          ],
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Lỗi tải dữ liệu chi tiết: $err',
              style: TextStyle(color: colors.expenseRed),
            ),
          ),
        ),
      ),
    );
  }
}
