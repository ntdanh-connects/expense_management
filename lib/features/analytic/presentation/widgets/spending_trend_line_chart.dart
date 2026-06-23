import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'hide TextDirection;
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';

// 📐 VẼ CUSTOM LINE CHART XU HƯỚNG CHI TIÊU HÀNG NGÀY (CÓ TƯƠNG TÁC CHẠM & ĐƯỜNG CONG BEZIER)
class SpendingTrendLineChart extends ConsumerStatefulWidget {
  final List<ReportTrendEntryDto> data;
  final AppColorsExtension colors;
  final String trendType;
  final String trendLineVisibility;

  const SpendingTrendLineChart({
    super.key,
    required this.data,
    required this.colors,
    required this.trendType,
    required this.trendLineVisibility,
  });

  @override
  ConsumerState<SpendingTrendLineChart> createState() => _SpendingTrendLineChartState();
}

class _SpendingTrendLineChartState extends ConsumerState<SpendingTrendLineChart> {
  int? _selectedIndex;

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'no_trend_data'.tr(ref),
            style: TextStyle(color: widget.colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final data = widget.data;
    final isEnglish = ref.watch(localeProvider) == 'en';

    // Find max value to scale dynamically based on visible lines
    double maxVal = 0;
    double totalIncome = 0;
    double totalExpense = 0;
    for (var entry in data) {
      if (widget.trendLineVisibility == 'all' || widget.trendLineVisibility == 'income') {
        if (entry.income > maxVal) maxVal = entry.income;
      }
      if (widget.trendLineVisibility == 'all' || widget.trendLineVisibility == 'expense') {
        if (entry.expense > maxVal) maxVal = entry.expense;
      }
      totalIncome += entry.income;
      totalExpense += entry.expense;
    }
    if (maxVal == 0) maxVal = 1.0;

    // Selected point details
    final selectedEntry = _selectedIndex != null && _selectedIndex! < data.length ? data[_selectedIndex!] : null;

    final showIncomeInDetails = widget.trendLineVisibility == 'all' || widget.trendLineVisibility == 'income';
    final showExpenseInDetails = widget.trendLineVisibility == 'all' || widget.trendLineVisibility == 'expense';

    return LayoutBuilder(
      builder: (context, constraints) {
        final paddingLeft = 36.0;
        final paddingRight = 10.0;
        final chartWidth = constraints.maxWidth - paddingLeft - paddingRight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Overlay Panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.colors.textSecondary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.colors.textSecondary.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedEntry != null
                            ? (selectedEntry.date != null 
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(selectedEntry.date!))
                                : selectedEntry.label)
                            : (isEnglish ? 'Period Overview' : 'Tổng quan chu kỳ'),
                        style: TextStyle(
                          color: widget.colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (selectedEntry != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.colors.textSecondary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded, size: 14, color: widget.colors.textSecondary),
                          ),
                        )
                      else
                        Text(
                          isEnglish ? 'Tap chart to inspect' : 'Chạm biểu đồ để xem chi tiết',
                          style: TextStyle(
                            color: widget.colors.textSecondary.withOpacity(0.5),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // Income Column
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: showIncomeInDetails ? 1.0 : 0.25,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEnglish ? 'Income' : 'Thu nhập',
                                  style: TextStyle(
                                    color: widget.colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedEntry != null ? _formatCurrency(selectedEntry.income) : _formatCurrency(totalIncome),
                                  style: TextStyle(
                                    color: widget.colors.incomeGreen,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: widget.colors.textSecondary.withOpacity(0.12),
                          thickness: 1,
                          width: 24,
                        ),
                        // Expense Column
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: showExpenseInDetails ? 1.0 : 0.25,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEnglish ? 'Expense' : 'Chi tiêu',
                                  style: TextStyle(
                                    color: widget.colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedEntry != null ? _formatCurrency(selectedEntry.expense) : _formatCurrency(totalExpense),
                                  style: TextStyle(
                                    color: widget.colors.expenseRed,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onPanStart: (details) => _handleTouch(details.localPosition, chartWidth, paddingLeft, data.length),
              onPanUpdate: (details) => _handleTouch(details.localPosition, chartWidth, paddingLeft, data.length),
              onTapDown: (details) => _handleTouch(details.localPosition, chartWidth, paddingLeft, data.length),
              child: SizedBox(
                height: 160,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: LineChartPainter(
                    data: data,
                    maxVal: maxVal,
                    colors: widget.colors,
                    selectedIndex: _selectedIndex,
                    trendType: widget.trendType,
                    trendLineVisibility: widget.trendLineVisibility,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTouch(Offset localPosition, double chartWidth, double paddingLeft, int dataLength) {
    if (chartWidth <= 0 || dataLength <= 1) return;
    final x = localPosition.dx - paddingLeft;
    final stepX = chartWidth / (dataLength - 1);
    final index = (x / stepX).round().clamp(0, dataLength - 1);
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<ReportTrendEntryDto> data;
  final double maxVal;
  final AppColorsExtension colors;
  final int? selectedIndex;
  final String trendType;
  final String trendLineVisibility;

  LineChartPainter({
    required this.data,
    required this.maxVal,
    required this.colors,
    this.selectedIndex,
    required this.trendType,
    required this.trendLineVisibility,
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

    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = colors.textSecondary.withOpacity(0.06)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 3 levels of horizontal grids (0%, 50%, 100%)
    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + chartHeight - (i / 2) * chartHeight;
      final val = (i / 2) * maxVal;

      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      String labelText = _formatCompact(val);
      textPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    final pointsIncome = <Offset>[];
    final pointsExpense = <Offset>[];
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * stepX;
      
      final valIncome = data[i].income;
      final yIncome = paddingTop + chartHeight - (valIncome / maxVal) * chartHeight;
      pointsIncome.add(Offset(x, yIncome));

      final valExpense = data[i].expense;
      final yExpense = paddingTop + chartHeight - (valExpense / maxVal) * chartHeight;
      pointsExpense.add(Offset(x, yExpense));
    }

    void drawCurveAndGradient(List<Offset> points, Color color) {
      if (points.isEmpty) return;

      // 1. Draw Gradient Area below the curve
      final fillPath = Path();
      fillPath.moveTo(paddingLeft, paddingTop + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);
      
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      }
      
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final gradient = LinearGradient(
        colors: [
          color.withOpacity(0.12),
          color.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // 2. Draw Smooth Line
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw visible curves
    if (trendLineVisibility == 'all' || trendLineVisibility == 'income') {
      drawCurveAndGradient(pointsIncome, colors.incomeGreen);
    }
    if (trendLineVisibility == 'all' || trendLineVisibility == 'expense') {
      drawCurveAndGradient(pointsExpense, colors.expenseRed);
    }

    // Highlight selected index
    if (selectedIndex != null && selectedIndex! < pointsIncome.length) {
      final selectedPointIncome = pointsIncome[selectedIndex!];
      final selectedPointExpense = pointsExpense[selectedIndex!];

      // Draw dashed reference line
      final guidePaint = Paint()
        ..color = colors.textSecondary.withOpacity(0.2)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      double currentY = paddingTop;
      final dashHeight = 4.0;
      final gapHeight = 4.0;
      while (currentY < paddingTop + chartHeight) {
        canvas.drawLine(
          Offset(selectedPointIncome.dx, currentY),
          Offset(selectedPointIncome.dx, (currentY + dashHeight).clamp(paddingTop, paddingTop + chartHeight)),
          guidePaint,
        );
        currentY += dashHeight + gapHeight;
      }

      // Draw focal dots for visible curves
      if (trendLineVisibility == 'all' || trendLineVisibility == 'income') {
        _drawFocalDot(canvas, selectedPointIncome, colors.incomeGreen);
      }
      if (trendLineVisibility == 'all' || trendLineVisibility == 'expense') {
        _drawFocalDot(canvas, selectedPointExpense, colors.expenseRed);
      }
    } else {
      // Draw small dot on last point for premium visual weight (only for visible lines)
      if (trendLineVisibility == 'all' || trendLineVisibility == 'income') {
        if (pointsIncome.isNotEmpty) {
          _drawEndDot(canvas, pointsIncome.last, colors.incomeGreen);
        }
      }
      if (trendLineVisibility == 'all' || trendLineVisibility == 'expense') {
        if (pointsExpense.isNotEmpty) {
          _drawEndDot(canvas, pointsExpense.last, colors.expenseRed);
        }
      }
    }

    // Draw X labels (max 5)
    final labelCount = data.length < 5 ? data.length : 5;
    final labelStep = data.length > 1 ? (data.length - 1) / (labelCount - 1) : 1;

    for (int i = 0; i < labelCount; i++) {
      final index = (i * labelStep).round();
      if (index >= data.length) continue;

      final point = pointsIncome[index];

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

  void _drawFocalDot(Canvas canvas, Offset point, Color color) {
    final haloPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 9.0, haloPaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 4.5, dotPaint);

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(point, 4.5, dotBorderPaint);
  }

  void _drawEndDot(Canvas canvas, Offset point, Color color) {
    final lastDotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 3.0, lastDotPaint);
    
    final lastDotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(point, 3.0, lastDotBorderPaint);
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
      oldDelegate.data != data || 
      oldDelegate.maxVal != maxVal || 
      oldDelegate.colors != colors ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.trendType != trendType ||
      oldDelegate.trendLineVisibility != trendLineVisibility;
}
