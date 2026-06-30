import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class ExportHistoryTabBar extends ConsumerWidget {
  final int activeIndex;
  final ValueChanged<int> onTabChanged;
  final int totalCount;
  final int pdfCount;
  final int csvCount;

  const ExportHistoryTabBar({
    super.key,
    required this.activeIndex,
    required this.onTabChanged,
    required this.totalCount,
    required this.pdfCount,
    required this.csvCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Row(
        children: [
          _buildTabChip(context, ref, 0, '${'all'.tr(ref)} ($totalCount)'),
          const SizedBox(width: 8),
          _buildTabChip(context, ref, 1, 'PDF ($pdfCount)'),
          const SizedBox(width: 8),
          _buildTabChip(context, ref, 2, 'Excel ($csvCount)'),
        ],
      ),
    );
  }

  Widget _buildTabChip(
      BuildContext context, WidgetRef ref, int index, String label) {
    final colors = context.colors;
    final isActive = activeIndex == index;

    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.incomeGreen
              : colors.textSecondary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : colors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
