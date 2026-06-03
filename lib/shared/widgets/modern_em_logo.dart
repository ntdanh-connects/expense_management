import 'dart:math' as math;
import 'package:flutter/material.dart';

class ModernEMLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const ModernEMLogo({
    super.key,
    this.size = 100,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.02,
                ),
              ],
            )
          : null,
      child: ClipOval(
        child: CustomPaint(
          painter: _EMLogoPainter(),
        ),
      ),
    );
  }
}

class _EMLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Radius of the split circle logo
    final R = w * 0.45;
    final gap = w * 0.04; // The vertical gap in the middle splitting E and M
    
    // Centers of the left and right semi-circles
    final leftCenterX = w / 2 - gap / 2;
    final rightCenterX = w / 2 + gap / 2;
    final centerY = h / 2;

    // 1. --- LEFT HALF: LETTER "E" ---
    final leftSemiCircle = Path()
      ..moveTo(leftCenterX, centerY - R)
      ..arcTo(
        Rect.fromCircle(center: Offset(leftCenterX, centerY), radius: R),
        1.5 * math.pi,
        -math.pi,
        false,
      )
      ..lineTo(leftCenterX, centerY + R)
      ..close();

    final stemWidth = R * 0.28;
    final barHeight = R * 0.22;

    // Two rectangular cutouts to carve out the "E" shape from the left semi-circle
    // The cutouts start from the inner split line and go left, leaving a curved stem on the outer left edge
    final topCutout = Path()
      ..addRect(Rect.fromLTRB(
        leftCenterX - R + stemWidth,
        centerY - R + barHeight,
        leftCenterX,
        centerY - barHeight / 2,
      ));

    final bottomCutout = Path()
      ..addRect(Rect.fromLTRB(
        leftCenterX - R + stemWidth,
        centerY + barHeight / 2,
        leftCenterX,
        centerY + R - barHeight,
      ));

    // Combine to get E Shape
    final eShape = Path.combine(
      PathOperation.difference,
      leftSemiCircle,
      Path.combine(PathOperation.union, topCutout, bottomCutout),
    );

    // 2. --- RIGHT HALF: LETTER "M" ---
    final rightSemiCircle = Path()
      ..moveTo(rightCenterX, centerY - R)
      ..arcTo(
        Rect.fromCircle(center: Offset(rightCenterX, centerY), radius: R),
        1.5 * math.pi,
        math.pi,
        false,
      )
      ..lineTo(rightCenterX, centerY + R)
      ..close();

    // M Cutouts
    final mStemWidth = R * 0.28;

    // Bottom cutout (the vertical space between the left and right legs of the M)
    final mBottomCutout = Path()
      ..addRect(Rect.fromLTRB(
        rightCenterX + mStemWidth,
        centerY + R * 0.32,
        rightCenterX + R - mStemWidth,
        centerY + R,
      ));

    // Top cutout (the V-shaped space in the middle of the M)
    final mTopCutout = Path()
      ..moveTo(rightCenterX + mStemWidth, centerY - R)
      ..lineTo(rightCenterX + mStemWidth, centerY - R * 0.4)
      ..lineTo(rightCenterX + R * 0.52, centerY + R * 0.1) // V-peak
      ..lineTo(rightCenterX + R, centerY - R * 0.3)
      ..lineTo(rightCenterX + R, centerY - R)
      ..close();

    // Combine to get M Shape
    final mShape = Path.combine(
      PathOperation.difference,
      rightSemiCircle,
      Path.combine(PathOperation.union, mBottomCutout, mTopCutout),
    );

    // 3. --- PAINTS & GRADIENTS ---
    // Left half (E) has a vibrant purple/violet gradient
    final leftPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFC084FC), // Bright Lavender/Purple
          Color(0xFF8B5CF6), // Violet
          Color(0xFF5B21B6), // Dark Indigo/Purple
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(leftCenterX, centerY), radius: R));

    // Right half (M) has a dark indigo/slate gradient with a subtle purple reflection at the bottom-left
    final rightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF312E81), // Dark Indigo
          Color(0xFF1E1B4B), // Deep Slate/Black
          Color(0xFF111827), // Almost Black
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: Offset(rightCenterX, centerY), radius: R));

    // Draw paths to canvas
    canvas.drawPath(eShape, leftPaint);
    canvas.drawPath(mShape, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
