import 'dart:math';
import 'package:flutter/material.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';

class ChartSegment {
  final Color color;
  final double percentage;
  ChartSegment({required this.color, required this.percentage});
}

class DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double strokeWidth;
  final int? selectedIndex;

  DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -pi / 2; // Bắt đầu ở góc 12h

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = segment.percentage * 2 * pi;

      if (i == selectedIndex) {
        final double bisectorAngle = startAngle + sweepAngle / 2;
        final double shiftDistance = 6.0;
        final Offset shiftOffset = Offset(
          cos(bisectorAngle) * shiftDistance,
          sin(bisectorAngle) * shiftDistance,
        );
        final Rect shiftedRect = rect.shift(shiftOffset);

        // 1. Vẽ hiệu ứng tỏa sáng hào quang (Glow shadow) phía dưới
        final glowPaint = Paint()
          ..color = segment.color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 8.0 // phình to hào quang
          ..strokeCap = StrokeCap.butt
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0); // mờ nhòe ánh sáng
        canvas.drawArc(shiftedRect, startAngle, sweepAngle, false, glowPaint);

        // 2. Vẽ nét vẽ chính phình to (Swell stroke)
        final paint = Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4.0 // phình to nét chính
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(shiftedRect, startAngle, sweepAngle, false, paint);
      } else {
        final paint = Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GroupedCategory {
  final String id;
  final String name;
  final String color;
  final String? icon;
  final double amount;
  final double percentage;
  final List<ReportCategoryEntryDto> subCategories;

  GroupedCategory({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.amount,
    required this.percentage,
    required this.subCategories,
  });
}
