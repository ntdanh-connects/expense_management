import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';

import '../widgets/balance_fluctuation_tab/fluctuation_time_selector.dart';
import '../widgets/balance_fluctuation_tab/fluctuation_type_selector.dart';
import '../widgets/balance_fluctuation_tab/fluctuation_chart_section.dart';
import '../widgets/balance_fluctuation_tab/fluctuation_breakdown_section.dart';
import '../widgets/balance_fluctuation_tab/fluctuation_shimmer.dart';

class BalanceFluctuationTab extends ConsumerStatefulWidget {
  const BalanceFluctuationTab({super.key});

  @override
  ConsumerState<BalanceFluctuationTab> createState() => _BalanceFluctuationTabState();
}

class _BalanceFluctuationTabState extends ConsumerState<BalanceFluctuationTab> {
  String _timeMode = 'month'; // 'week', 'month', 'year'
  String _typeMode = 'expense'; // 'income', 'expense', 'difference'
  int _selectedPeriodIndex = -1;
  bool _isCompareEnabled = true;
  
  final ScrollController _chartScrollController = ScrollController();

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
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

  void _scrollToEnd() {
    if (_chartScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_chartScrollController.hasClients) {
          _chartScrollController.animateTo(
            _chartScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';
    final trendsAsync = ref.watch(trendsFlexibleProvider(_timeMode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📊 1. LEVEL 1 TIME SELECTOR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: FluctuationTimeSelector(
            timeMode: _timeMode,
            onTimeModeChanged: (val) {
              setState(() {
                _timeMode = val;
                _selectedPeriodIndex = -1;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToEnd();
              });
            },
          ),
        ),
        const SizedBox(height: 18),

        // 📊 MAIN CONTENT BOX
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 2. LEVEL 2 TYPE SELECTOR
              FluctuationTypeSelector(
                typeMode: _typeMode,
                onTypeModeChanged: (val) {
                  setState(() {
                    _typeMode = val;
                  });
                },
              ),
              const SizedBox(height: 24),

              trendsAsync.when(
                data: (trends) {
                  if (trends.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'no_trend_data'.tr(ref),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }

                  if (_selectedPeriodIndex == -1 || _selectedPeriodIndex >= trends.length) {
                    _selectedPeriodIndex = trends.length - 1;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToEnd();
                    });
                  }

                  final selectedTrend = trends[_selectedPeriodIndex];
                  final periodRange = _getPeriodRange(selectedTrend, _timeMode);

                  double totalAmount = 0.0;
                  if (_typeMode == 'expense') {
                    totalAmount = selectedTrend.expense;
                  } else if (_typeMode == 'income') {
                    totalAmount = selectedTrend.income;
                  } else {
                    totalAmount = selectedTrend.income - selectedTrend.expense;
                  }

                  double maxChartVal = 1.0;
                  for (var t in trends) {
                    if (_typeMode == 'expense' && t.expense > maxChartVal) maxChartVal = t.expense;
                    if (_typeMode == 'income' && t.income > maxChartVal) maxChartVal = t.income;
                    if (_typeMode == 'difference') {
                      final net = (t.income - t.expense).abs();
                      if (net > maxChartVal) maxChartVal = net;
                    }
                  }

                  double diffVal = 0.0;
                  String compLabel = '';
                  if (_selectedPeriodIndex > 0) {
                    final prevTrend = trends[_selectedPeriodIndex - 1];
                    final prevVal = _typeMode == 'expense'
                        ? prevTrend.expense
                        : (_typeMode == 'income' ? prevTrend.income : (prevTrend.income - prevTrend.expense));
                    diffVal = totalAmount - prevVal;
                    compLabel = prevTrend.label;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 💵 3. SUMMARY SECTION
                      _buildSummarySection(totalAmount, diffVal, compLabel, colors, isEnglish),
                      const SizedBox(height: 24),

                      // 📊 4. CHART SECTION
                      FluctuationChartSection(
                        trends: trends,
                        maxVal: maxChartVal,
                        selectedPeriodIndex: _selectedPeriodIndex,
                        onPeriodSelected: (idx) {
                          setState(() {
                            _selectedPeriodIndex = idx;
                          });
                        },
                        isCompareEnabled: _isCompareEnabled,
                        onCompareToggle: (val) {
                          setState(() {
                            _isCompareEnabled = val;
                          });
                        },
                        timeMode: _timeMode,
                        typeMode: _typeMode,
                        chartScrollController: _chartScrollController,
                      ),
                      const SizedBox(height: 24),

                      // ⚙️ 5. BREAKDOWN VIEW
                      FluctuationBreakdownSection(
                        periodRange: periodRange,
                        totalPeriodAmount: totalAmount,
                        trends: trends,
                        selectedPeriodIndex: _selectedPeriodIndex,
                        onPeriodSelected: (idx) {
                          setState(() {
                            _selectedPeriodIndex = idx;
                          });
                        },
                        timeMode: _timeMode,
                        typeMode: _typeMode,
                        isCompareEnabled: _isCompareEnabled,
                      ),
                    ],
                  );
                },
                loading: () => const FluctuationShimmer(),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      '${'load_fluctuation_error'.tr(ref)}: $err',
                      style: TextStyle(color: colors.expenseRed, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(
    double totalAmount,
    double diffVal,
    String compLabel,
    AppColorsExtension colors,
    bool isEnglish,
  ) {
    String periodTitle = '';
    if (_timeMode == 'week') {
      periodTitle = isEnglish ? 'this week' : 'tuần';
    } else if (_timeMode == 'month') {
      periodTitle = isEnglish ? 'this month' : 'tháng';
    } else {
      periodTitle = isEnglish ? 'this year' : 'năm';
    }

    String typeLabel = '';
    if (_typeMode == 'expense') {
      typeLabel = 'total_expense_period'.tr(ref);
    } else if (_typeMode == 'income') {
      typeLabel = 'total_income_period'.tr(ref);
    } else {
      typeLabel = 'total_difference_period'.tr(ref);
    }

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$typeLabel $periodTitle',
            style: TextStyle(color: colors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(totalAmount),
            style: TextStyle(
              color: _typeMode == 'difference'
                  ? (totalAmount >= 0 ? colors.incomeGreen : colors.expenseRed)
                  : colors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Comparison box
          if (_isCompareEnabled && compLabel.isNotEmpty)
            _buildComparisonBox(diffVal, compLabel, colors, isEnglish),
        ],
      ),
    );
  }

  Widget _buildComparisonBox(double diffVal, String compLabel, AppColorsExtension colors, bool isEnglish) {
    final isIncrease = diffVal > 0;
    final isDecrease = diffVal < 0;

    Color bg;
    Color fg;
    String text;
    IconData icon;

    final formattedAmt = _formatCurrency(diffVal.abs());

    if (isIncrease) {
      bg = const Color(0xFFFFF0EC);
      fg = const Color(0xFFFF5722);
      text = 'increase_vs_prev'
          .tr(ref)
          .replaceAll('{amount}', formattedAmt)
          .replaceAll('{period}', compLabel);
      icon = Icons.arrow_upward_rounded;
    } else if (isDecrease) {
      bg = const Color(0xFFEAF9EE);
      fg = const Color(0xFF2E7D32);
      text = 'decrease_vs_prev'
          .tr(ref)
          .replaceAll('{amount}', formattedAmt)
          .replaceAll('{period}', compLabel);
      icon = Icons.arrow_downward_rounded;
    } else {
      bg = colors.textSecondary.withOpacity(0.08);
      fg = colors.textSecondary;
      text = 'unchanged_vs_prev'
          .tr(ref)
          .replaceAll('{period}', compLabel);
      icon = Icons.remove_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
