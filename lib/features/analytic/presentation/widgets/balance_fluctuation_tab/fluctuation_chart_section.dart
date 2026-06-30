import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';

class FluctuationChartSection extends StatelessWidget {
  final List<ReportTrendEntryDto> trends;
  final double maxVal;
  final int selectedPeriodIndex;
  final ValueChanged<int> onPeriodSelected;
  final bool isCompareEnabled;
  final ValueChanged<bool> onCompareToggle;
  final String timeMode;
  final String typeMode;
  final ScrollController chartScrollController;

  const FluctuationChartSection({
    super.key,
    required this.trends,
    required this.maxVal,
    required this.selectedPeriodIndex,
    required this.onPeriodSelected,
    required this.isCompareEnabled,
    required this.onCompareToggle,
    required this.timeMode,
    required this.typeMode,
    required this.chartScrollController,
  });

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                  value: isCompareEnabled,
                  activeColor: colors.primary,
                  onChanged: onCompareToggle,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildChartWithYAxis(context, colors),
      ],
    );
  }

  Widget _buildChartWithYAxis(BuildContext context, AppColorsExtension colors) {
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
        // Y-axis
        Container(
          height: 170,
          width: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 35 - 20,
                right: 0,
                child: Text(
                  unit,
                  style: TextStyle(fontSize: 9, color: colors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
              ...List.generate(5, (index) {
                final double yPosition = 35 + (110 * (index / 4));
                return Positioned(
                  top: yPosition - 6,
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
        // Scrollable Chart area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double minColumnWidth = timeMode == 'year' ? 120.0 : (timeMode == 'week' ? 65.0 : 55.0);
              final double computedWidth = trends.length * minColumnWidth + 32.0;
              final double chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;

              return SingleChildScrollView(
                controller: chartScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: chartWidth,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Grid lines
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
                      // Bar columns
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(trends.length, (index) {
                              final trend = trends[index];
                              final isSelected = index == selectedPeriodIndex;

                              double opacity = 1.0;
                              if (!isCompareEnabled) {
                                opacity = isSelected ? 1.0 : 0.25;
                              }

                              if (typeMode == 'difference') {
                                final net = trend.income - trend.expense;
                                return GestureDetector(
                                  onTap: () => onPeriodSelected(index),
                                  child: Opacity(
                                    opacity: opacity,
                                    child: _buildBidirectionalBar(trend.label, net, maxVal, colors, isSelected, timeMode),
                                  ),
                                );
                              } else {
                                final val = typeMode == 'expense' ? trend.expense : trend.income;
                                final double pct = val / maxVal;
                                return GestureDetector(
                                  onTap: () => onPeriodSelected(index),
                                  child: Opacity(
                                    opacity: opacity,
                                    child: _buildSingleBar(trend.label, val, pct, colors, isSelected, timeMode),
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
        Container(
          height: 110,
          width: barWidth,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: barWidth,
                height: (110 * pct).clamp(4.0, 110.0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
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
    final double barHeight = 55 * pct;
    final double barWidth = timeMode == 'year' ? 38.0 : 26.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 110,
          width: barWidth,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -4,
                right: -4,
                top: 54.25,
                height: 1.5,
                child: Container(
                  color: colors.textSecondary.withOpacity(0.3),
                ),
              ),
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
}
