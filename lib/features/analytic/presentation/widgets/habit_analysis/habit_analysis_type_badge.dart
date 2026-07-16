import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class HabitAnalysisTypeBadge extends StatelessWidget {
  final String type;
  const HabitAnalysisTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (type) {
      case 'monthly':
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange.shade700;
        label = 'Tháng';
        icon = Icons.calendar_month_rounded;
        break;
      case 'yearly':
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple.shade400;
        label = 'Năm';
        icon = Icons.star_rounded;
        break;
      default:
        bg = colors.primary.withOpacity(0.12);
        fg = colors.primary;
        label = 'Ngày';
        icon = Icons.today_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
