import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

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
  String _categoryMode = 'child'; // 'child', 'parent'
  
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch the trend entries
    final trendsAsync = ref.watch(trendsFlexibleProvider(_timeMode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📊 1. LEVEL 1 TIME SELECTOR (Bọc viền cho đẹp)
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
          child: _buildLevel1TimeSelector(colors),
        ),
        const SizedBox(height: 18),

        // 📊 từ các tab thu chi chênh lệch trở xuống bọc lại
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
              // 📊 2. LEVEL 2 TYPE SELECTOR (Thu nhập, Chi tiêu, Chênh lệch)
              _buildLevel2TypeSelector(colors),
              const SizedBox(height: 24),

              trendsAsync.when(
                data: (trends) {
                  if (trends.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'no_trend_data'.tr(ref),
                          style: TextStyle(color: colors.textSecondary, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  // Reset selected index if it is out of bounds or initialized as -1
                  if (_selectedPeriodIndex == -1 || _selectedPeriodIndex >= trends.length) {
                    _selectedPeriodIndex = trends.length - 1;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToEnd();
                    });
                  }

                  final selectedTrend = trends[_selectedPeriodIndex];
                  final periodRange = _getPeriodRange(selectedTrend, _timeMode);

                  // Calculate total amount depending on type selection
                  double totalAmount = 0.0;
                  if (_typeMode == 'expense') {
                    totalAmount = selectedTrend.expense;
                  } else if (_typeMode == 'income') {
                    totalAmount = selectedTrend.income;
                  } else {
                    totalAmount = selectedTrend.income - selectedTrend.expense;
                  }

                  // Find Max Value for scaling bar chart
                  double maxChartVal = 1.0;
                  for (var t in trends) {
                    if (_typeMode == 'expense' && t.expense > maxChartVal) maxChartVal = t.expense;
                    if (_typeMode == 'income' && t.income > maxChartVal) maxChartVal = t.income;
                    if (_typeMode == 'difference') {
                      final net = (t.income - t.expense).abs();
                      if (net > maxChartVal) maxChartVal = net;
                    }
                  }

                  // Calculation for comparison box
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
                      // 💵 3. SUMMARY SECTION (Tổng tiền + So sánh cùng kỳ CĂN GIỮA)
                      _buildSummarySection(totalAmount, diffVal, compLabel, colors),
                      const SizedBox(height: 24),

                      // 📊 4. CHART SECTION (Cột to lên, Y-axis bên trái và lưới phụ)
                      _buildChartSection(trends, maxChartVal, colors),
                      const SizedBox(height: 24),

                      // ⚙️ 5. BREAKDOWN VIEW (Nằm dưới biểu đồ)
                      if (_typeMode != 'difference') ...[
                        _buildBreakdownSection(periodRange, totalAmount, trends, colors),
                      ] else ...[
                        _buildNetDifferenceList(trends, colors),
                      ],
                    ],
                  );
                },
                loading: () => _buildShimmerLoading(colors),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Lỗi tải dữ liệu biến động: $err',
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

  // Segmented control bo góc mịn MoMo style
  Widget _buildLevel1TimeSelector(AppColorsExtension colors) {
    final isEnglish = ref.watch(localeProvider) == 'en';
    final tabs = {
      'week': isEnglish ? 'Weekly' : 'Theo tuần',
      'month': isEnglish ? 'Monthly' : 'Theo tháng',
      'year': isEnglish ? 'Yearly' : 'Theo năm',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.textSecondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs.keys.map((key) {
          final isSelected = _timeMode == key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _timeMode = key;
                  _selectedPeriodIndex = -1;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToEnd();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tabs[key]!,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevel2TypeSelector(AppColorsExtension colors) {
    final tabs = {
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'difference': 'Chênh lệch',
    };

    return Row(
      children: tabs.keys.map((key) {
        final isSelected = _typeMode == key;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _typeMode = key;
              });
            },
            child: Column(
              children: [
                Text(
                  tabs[key]!,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummarySection(
    double totalAmount,
    double diffVal,
    String compLabel,
    AppColorsExtension colors,
  ) {
    String periodTitle = '';
    if (_timeMode == 'week') {
      periodTitle = 'tuần này';
    } else if (_timeMode == 'month') {
      periodTitle = 'tháng này';
    } else {
      periodTitle = 'năm nay';
    }

    if (_selectedPeriodIndex != -1) {
      if (_timeMode == 'week') {
        periodTitle = 'tuần';
      } else if (_timeMode == 'month') {
        periodTitle = 'tháng';
      } else {
        periodTitle = 'năm';
      }
    }

    String typeLabel = '';
    if (_typeMode == 'expense') {
      typeLabel = 'Tổng chi';
    } else if (_typeMode == 'income') {
      typeLabel = 'Tổng thu';
    } else {
      typeLabel = 'Tổng chênh lệch';
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
            _buildComparisonBox(diffVal, compLabel, colors),
        ],
      ),
    );
  }

  Widget _buildComparisonBox(double diffVal, String compLabel, AppColorsExtension colors) {
    final isIncrease = diffVal > 0;
    final isDecrease = diffVal < 0;

    Color bg;
    Color fg;
    String text;
    IconData icon;

    if (isIncrease) {
      bg = const Color(0xFFFFF0EC);
      fg = const Color(0xFFFF5722);
      text = 'Tăng ${_formatCurrency(diffVal)} so với cùng kỳ $compLabel';
      icon = Icons.arrow_upward_rounded;
    } else if (isDecrease) {
      bg = const Color(0xFFEAF9EE);
      fg = const Color(0xFF2E7D32);
      text = 'Giảm ${_formatCurrency(-diffVal)} so với cùng kỳ $compLabel';
      icon = Icons.arrow_downward_rounded;
    } else {
      bg = colors.textSecondary.withOpacity(0.08);
      fg = colors.textSecondary;
      text = 'Không đổi so với cùng kỳ $compLabel';
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

  Widget _buildChartSection(
    List<ReportTrendEntryDto> trends,
    double maxVal,
    AppColorsExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Biến động',
              style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  'So với cùng kỳ',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                CupertinoSwitch(
                  value: _isCompareEnabled,
                  activeColor: colors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isCompareEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Biểu đồ lưới phụ có cột to lên và mức tiền bên trái
        _buildChartWithYAxis(trends, maxVal, colors),
      ],
    );
  }

  Widget _buildChartWithYAxis(List<ReportTrendEntryDto> trends, double maxVal, AppColorsExtension colors) {
    final levels = [1.0, 0.75, 0.5, 0.25, 0.0];
    final tickLabels = levels.map((lvl) => _formatTick(maxVal * lvl)).toList();

    String unit = '(đ)';
    if (maxVal >= 1000000) {
      unit = '(Tr)';
    } else if (maxVal >= 1000) {
      unit = '(K)';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. Cột mức tiền cố định bên trái (Y-axis) - căn chỉnh hoàn hảo từng pixel
        Container(
          height: 170, // Tổng chiều cao của khu vực biểu đồ tăng lên 160px
          width: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Phần đơn vị nằm phía trên mức cao nhất (vạch 1.0 ở 35px)
              Positioned(
                top: 35 - 20, // đặt cao hẳn lên (y = 15) để tránh dính chữ vào số
                right: 0,
                child: Text(
                  unit,
                  style: TextStyle(fontSize: 9, color: colors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
              // 5 mức tiền khớp hoàn hảo với trung tâm của 5 đường kẻ ngang
              ...List.generate(5, (index) {
                final double yPosition = 35 + (110 * (index / 4));
                return Positioned(
                  top: yPosition - 6, // căn giữa hoàn hảo chữ
                  right: 0,
                  child: Text(
                    tickLabels[index],
                    style: TextStyle(fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 2. Vùng biểu đồ cuộn ngang chứa lưới và cột - tự động co giãn nếu ít cột
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double minColumnWidth = _timeMode == 'year' ? 120.0 : (_timeMode == 'week' ? 65.0 : 55.0);
              // Thêm 32px padding ngang vào computedWidth để không bị chật hai đầu
              final double computedWidth = trends.length * minColumnWidth + 32.0;
              final double chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;

              return SingleChildScrollView(
                controller: _chartScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: chartWidth,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Các đường kẻ ngang làm lưới phụ (sau các cột)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 15,
                        top: 35,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (index) => Container(
                              height: 0.5,
                              color: colors.textSecondary.withOpacity(0.12),
                            ),
                          ),
                        ),
                      ),
                      // Các cột dữ liệu
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16), // Thêm padding ngang 16px tránh cắt chữ đầu cuối
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(trends.length, (index) {
                              final trend = trends[index];
                              final isSelected = index == _selectedPeriodIndex;

                              // Highlight logic based on "So với cùng kỳ"
                              double opacity = 1.0;
                              if (!_isCompareEnabled) {
                                opacity = isSelected ? 1.0 : 0.25;
                              }

                              if (_typeMode == 'difference') {
                                final net = trend.income - trend.expense;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPeriodIndex = index;
                                    });
                                  },
                                  child: Opacity(
                                    opacity: opacity,
                                    child: _buildBidirectionalBar(trend.label, net, maxVal, colors, isSelected, _timeMode),
                                  ),
                                );
                              } else {
                                final val = _typeMode == 'expense' ? trend.expense : trend.income;
                                final double pct = val / maxVal;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPeriodIndex = index;
                                    });
                                  },
                                  child: Opacity(
                                    opacity: opacity,
                                    child: _buildSingleBar(trend.label, val, pct, colors, isSelected, _timeMode),
                                  ),
                                );
                              }
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleBar(
    String label,
    double value,
    double pct,
    AppColorsExtension colors,
    bool isSelected,
    String timeMode,
  ) {
    final barColor = isSelected ? colors.primary : colors.primary.withOpacity(0.25);
    final double barWidth = timeMode == 'year' ? 48.0 : 32.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Vùng vẽ cột cao 110px (từ y = 35 đến y = 145)
        Container(
          height: 110,
          width: barWidth,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Cột màu xanh
              Container(
                width: barWidth,
                height: (110 * pct).clamp(4.0, 110.0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              // Tooltip badge above selected column
              if (isSelected)
                Positioned(
                  bottom: (110 * pct).clamp(4.0, 110.0) + 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatCompact(value),
                      style: TextStyle(color: colors.surface, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Nhãn trục X cao 11px
        Container(
          height: 11,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.primary : colors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBidirectionalBar(
    String label,
    double netValue,
    double maxVal,
    AppColorsExtension colors,
    bool isSelected,
    String timeMode,
  ) {
    final isPositive = netValue >= 0;
    final double pct = maxVal > 0 ? (netValue.abs() / maxVal) : 0.0;
    final double barHeight = 55 * pct; // 55px max height on each side (total 110px)
    final double barWidth = timeMode == 'year' ? 38.0 : 26.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Vùng vẽ cột 2 hướng cao 110px (từ y = 35 đến y = 145)
        Container(
          height: 110,
          width: barWidth,
          child: Stack(
            alignment: Alignment.center, // để Zero Line nằm chính giữa
            clipBehavior: Clip.none,
            children: [
              // Zero Line
              Positioned(
                left: -4,
                right: -4,
                top: 54.25,
                height: 1.5,
                child: Container(
                  color: colors.textSecondary.withOpacity(0.3),
                ),
              ),
              // Cột dương
              if (isPositive && netValue > 0)
                Positioned(
                  bottom: 55,
                  height: barHeight.clamp(4.0, 55.0),
                  width: barWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : colors.incomeGreen.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              // Cột âm
              if (!isPositive && netValue < 0)
                Positioned(
                  top: 55,
                  height: barHeight.clamp(4.0, 55.0),
                  width: barWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : colors.expenseRed.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                    ),
                  ),
                ),
              // Tooltip
              if (isSelected)
                Positioned(
                  bottom: isPositive ? 55 + barHeight.clamp(4.0, 55.0) + 4 : null,
                  top: !isPositive ? 55 + barHeight.clamp(4.0, 55.0) + 4 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatCompact(netValue),
                      style: TextStyle(color: colors.surface, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Nhãn trục X cao 11px
        Container(
          height: 11,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.primary : colors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(
    DateTimeRange periodRange,
    double totalPeriodAmount,
    List<ReportTrendEntryDto> trends,
    AppColorsExtension colors,
  ) {
    // 1. Fetch current categories
    final categoriesAsync = ref.watch(categoriesByPeriodProvider((
      startDate: periodRange.start,
      endDate: periodRange.end,
      type: _typeMode,
    )));

    // 2. Fetch previous period categories if selected index > 0 to compute changes
    AsyncValue<ReportCategoryDto>? prevCategoriesAsync;
    if (_selectedPeriodIndex > 0) {
      final prevTrend = trends[_selectedPeriodIndex - 1];
      final prevRange = _getPeriodRange(prevTrend, _timeMode);
      prevCategoriesAsync = ref.watch(categoriesByPeriodProvider((
        startDate: prevRange.start,
        endDate: prevRange.end,
        type: _typeMode,
      )));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If chi_tieu -> show parent/child segmented selector (Full width)
        if (_typeMode == 'expense') ...[
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

            // Group categories if parent mode is active
            List<CategoryUIItem> uiItems = [];
            if (_typeMode == 'expense' && _categoryMode == 'parent') {
              uiItems = _groupCategoriesToUI(entries, totalPeriodAmount);
            } else {
              // Child mode or Income (always child mode)
              uiItems = entries
                  .map((e) => CategoryUIItem(
                        id: e.categoryId,
                        name: e.categoryName,
                        color: e.categoryColor ?? '9BFFE5',
                        icon: e.categoryIcon,
                        amount: e.amount,
                        percentage: totalPeriodAmount > 0 ? (e.amount / totalPeriodAmount) * 100 : 0.0,
                      ))
                  .toList();
            }

            uiItems.sort((a, b) => b.amount.compareTo(a.amount));

            // Compute comparison differences if previous period categories are available
            final prevData = prevCategoriesAsync?.value;
            final Map<String, double> prevAmounts = {};
            if (prevData != null) {
              if (_typeMode == 'expense' && _categoryMode == 'parent') {
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

                // Calculate change compared to previous period
                double diff = 0.0;
                bool showDiff = _isCompareEnabled && _selectedPeriodIndex > 0;
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
                        'type': _typeMode,
                        'startDate': periodRange.start,
                        'endDate': periodRange.end,
                        'timeMode': _timeMode,
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
                                  // Percentage indicator & compared label
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
          error: (err, stack) => Text('Lỗi breakdown: $err', style: TextStyle(color: colors.expenseRed)),
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

  // Group Categories locally to UI representation
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

  Widget _buildDateBadge(ReportTrendEntryDto trend, AppColorsExtension colors, bool isEnglish) {
    final dateStr = trend.date ?? '';
    final startDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    if (_timeMode == 'week') {
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
    } else if (_timeMode == 'month') {
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
      // year
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

  // Bảng thống kê thu/chi/còn lại cho tab chênh lệch (Hình 4)
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
            final isSelected = originalIndex == _selectedPeriodIndex;
            final net = trend.income - trend.expense;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriodIndex = originalIndex;
                });
              },
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

  String _formatTick(double value) {
    if (value >= 1000000) {
      return (value / 1000000).toStringAsFixed(1);
    } else if (value >= 1000) {
      return (value / 1000).toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  String _formatCompact(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M đ';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K đ';
    }
    return '${val.toStringAsFixed(0)}đ';
  }

  Widget _buildShimmerLoading(AppColorsExtension colors) {
    return Column(
      children: [
        _buildShimmerCard(height: 80, colors: colors),
        const SizedBox(height: 16),
        _buildShimmerCard(height: 180, colors: colors),
        const SizedBox(height: 16),
        _buildShimmerCard(height: 220, colors: colors),
      ],
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
