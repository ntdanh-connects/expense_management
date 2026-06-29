import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class OcrRawLineItem extends StatelessWidget {
  final String lineText;
  final VoidCallback onTap;

  const OcrRawLineItem({
    super.key,
    required this.lineText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 14,
                  color: color.primary.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lineText,
                    style: TextStyle(
                      color: color.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 16,
                  color: color.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
