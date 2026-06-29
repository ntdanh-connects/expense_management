import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FloatingAiButton extends StatefulWidget {
  const FloatingAiButton({super.key});

  @override
  State<FloatingAiButton> createState() => _FloatingAiButtonState();
}

class _FloatingAiButtonState extends State<FloatingAiButton> {
  bool _isInitialized = false;
  Offset offset = Offset.zero;
  bool isDragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final mediaQuery = MediaQuery.of(context);
      // Đặt ở cạnh phải màn hình, cách mép dưới khoảng 200px
      offset = Offset(
        mediaQuery.size.width - 72.0,
        mediaQuery.size.height - 200.0,
      );
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            double newX = offset.dx + details.delta.dx;
            double newY = offset.dy + details.delta.dy;

            // Giới hạn không cho kéo ra ngoài màn hình
            newX = newX.clamp(0.0, size.width - 56.0);
            newY = newY.clamp(
              mediaQuery.padding.top + 10.0,
              size.height - mediaQuery.padding.bottom - 90.0,
            );

            offset = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() => isDragging = false);
          // Hút về cạnh gần nhất (trái hoặc phải)
          final screenWidth = mediaQuery.size.width;
          double targetX =
              offset.dx < (screenWidth / 2) ? 16.0 : (screenWidth - 72.0);

          setState(() {
            offset = Offset(targetX, offset.dy);
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFFE91E63), // Pink
                Color(0xFF00BCD4), // Cyan
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withOpacity(0.4),
                blurRadius: isDragging ? 18 : 12,
                spreadRadius: isDragging ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/ai-assistant'),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
