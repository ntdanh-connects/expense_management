import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/ai_assistant/presentation/providers/habit_analysis_provider.dart';
import 'package:expense_management/features/analytic/presentation/widgets/habit_analysis/habit_analysis_type_badge.dart';
import 'package:intl/intl.dart';

class HabitAnalysisCard extends StatelessWidget {
  final HabitAnalysisEntry entry;
  final VoidCallback onTap;

  const HabitAnalysisCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String cleanSummary(dynamic rawSummary) {
      final str = rawSummary?.toString() ?? '';
      if (str.isEmpty ||
          str.toLowerCase().contains('lỗi') ||
          str.toLowerCase().contains('error') ||
          str.toLowerCase().contains('key') ||
          str.toLowerCase().contains('429')) {
        return 'Báo cáo thói quen chi tiêu. Nhấn để xem chi tiết.';
      }
      return str;
    }

    final rawSummary = entry.analysisData['summary'] ??
        entry.analysisData['insight'] ??
        entry.analysisData['analysis'] ??
        entry.analysisData['message'] ??
        'Nhấn để xem chi tiết';
        
    final summary = cleanSummary(rawSummary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(entry.isRead ? 0.04 : 0.07)
              : (entry.isRead ? Colors.white : const Color(0xFFF0F4FF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: entry.isRead
                ? colors.textSecondary.withOpacity(0.06)
                : colors.primary.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitAnalysisTypeBadge(type: entry.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.periodRange.isNotEmpty ? entry.periodRange : _formatDate(entry.analysisDate),
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
                if (!entry.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight: entry.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Xem chi tiết →',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
