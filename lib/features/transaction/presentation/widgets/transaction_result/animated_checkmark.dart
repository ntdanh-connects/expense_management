import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class AnimatedCheckmark extends StatefulWidget {
  final bool isSuccess;
  const AnimatedCheckmark({super.key, required this.isSuccess});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.isSuccess ? colors.incomeGreen : colors.expenseRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.isSuccess ? colors.incomeGreen : colors.expenseRed)
                  .withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          widget.isSuccess ? Icons.check_rounded : Icons.close_rounded,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}
