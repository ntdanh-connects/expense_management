import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_provider.dart';

class PeriodBucket {
  final DateTime start;
  final DateTime end;
  final String label;

  PeriodBucket({required this.start, required this.end, required this.label});
}

class CategoryDetailChart extends ConsumerWidget {
  final List<PeriodBucket> periods;
  final List<double> periodAmounts;
  final int selectedChartIndex;
  final ValueChanged<int> onChartIndexChanged;
  final double averageAmount;
  final String timeMode;

  const CategoryDetailChart({
    super.key,
    required this.periods,
    required this.periodAmounts,
    required this.selectedChartIndex,
    required this.onChartIndexChanged,
    required this.averageAmount,
    required this.timeMode,
  });

  String _formatTick(double value) {
    if (value >= 1000000) {
      return (value / 1000000).toStringAsFixed(1);
    } else if (value >= 1000) {
      return (value / 1000).toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  String _formatCompact(double val, bool isEnglish) {
    if (val >= 1000000000) {
      final v = val / 1000000000;
      final numStr = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      return isEnglish ? '${numStr}B' : '$numStr tỷ';
    } else if (val >= 1000000) {
      final v = val / 1000000;
      final numStr = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      return isEnglish ? '${numStr}M' : '$numStr tr';
    } else if (val >= 1000) {
      final v = val / 1000;
      final numStr = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(0);
      return isEnglish ? '${numStr}K' : '$numStr k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'Spending trend' : 'Xu hướng chi tiêu',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEnglish ? 'Tap column to filter transaction list below' : 'Nhấn vào cột để lọc danh sách giao dịch bên dưới',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxVal = averageAmount * 1.5;
                for (var amt in periodAmounts) {
                  if (amt > maxVal) maxVal = amt;
                }
                if (maxVal == 0) maxVal = 1.0;

                final levels = [1.0, 0.75, 0.5, 0.25, 0.0];
                final tickLabels = levels.map((lvl) => _formatTick(maxVal * lvl)).toList();

                String unit = '(đ)';
                if (maxVal >= 1000000000) {
                  unit = isEnglish ? '(B)' : '(tỷ đ)';
                } else if (maxVal >= 1000000) {
                  unit = isEnglish ? '(M)' : '(tr đ)';
                } else if (maxVal >= 1000) {
                  unit = isEnglish ? '(K)' : '(k đ)';
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y-axis
                    SizedBox(
                      height: 160,
                      width: 42,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 35 - 20,
                            right: 0,
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...List.generate(5, (index) {
                            final double yPosition = 35 + (110 * (index / 4));
                            return Positioned(
                              top: yPosition - 6,
                              right: 0,
                              child: Text(
                                tickLabels[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Scrollable Columns stacked with average line
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, chartConstraints) {
                          final double minColumnWidth = timeMode == 'year' ? 120.0 : 65.0;
                          final double computedWidth = periods.length * minColumnWidth + 32.0;
                          final double chartWidth = computedWidth > chartConstraints.maxWidth
                              ? computedWidth
                              : chartConstraints.maxWidth;

                           return Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: SizedBox(
                                  width: chartWidth,
                                  height: 160,
                                  child: Stack(
                                    alignment: Alignment.bottomLeft,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Grid background lines
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
                                              color: colors.textSecondary.withValues(alpha: 0.12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bar Chart Columns
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
                                            children: List.generate(
                                              periods.length,
                                              (index) {
                                                final amount = periodAmounts[index];
                                                final label = periods[index].label;
                                                final isSelected = index == selectedChartIndex;
                                                final pct = amount / maxVal;

                                                return GestureDetector(
                                                  onTap: () => onChartIndexChanged(index),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: _buildSingleBar(
                                                    label,
                                                    amount,
                                                    pct,
                                                    colors,
                                                    isSelected,
                                                    timeMode,
                                                    isEnglish,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBar(
    String label,
    double value,
    double pct,
    AppColorsExtension colors,
    bool isSelected,
    String timeMode,
    bool isEnglish,
  ) {
    final barColor = isSelected ? colors.primary : colors.primary.withValues(alpha: 0.25);
    final double barWidth = timeMode == 'year' ? 48.0 : 32.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
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
                      _formatCompact(value, isEnglish),
                      style: TextStyle(
                        color: colors.surface,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
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

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
