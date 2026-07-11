import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.24
      ..strokeCap = StrokeCap.butt;

    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - paint.strokeWidth / 2);

    // 1. Red Segment (Top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.4, 1.2, false, paint);

    // 2. Yellow Segment (Left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.6, 1.2, false, paint);

    // 3. Green Segment (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.4, false, paint);

    // 4. Blue Segment & Horizontal Bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.2, 2.0, false, paint);

    // Draw the horizontal bar
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final double barHeight = size.height * 0.24;
    final Rect barRect = Rect.fromLTWH(
      size.width * 0.5,
      size.height * 0.38,
      size.width * 0.44,
      barHeight,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
