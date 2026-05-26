import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeToggleButton extends ConsumerWidget {
  final double size;
  final Color? isColor;
  const ThemeToggleButton({super.key, this.size = 24, this.isColor});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = context.colors;

    return Container(
      decoration: BoxDecoration(
        gradient: color.authGradient,
        shape: BoxShape.circle
      ),
      child: IconButton(
        iconSize: size,
        onPressed: (){
          ref.read(themeProvider.notifier).toggleTheme();
      }, icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: isColor ?? (isDark ? Colors.amber : color.primary),
      )),
    );
  }
}