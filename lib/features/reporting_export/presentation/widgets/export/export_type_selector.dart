import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class ExportTypeSelector extends ConsumerWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const ExportTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'report_type'.tr(ref),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    context: context,
                    ref: ref,
                    id: 'pdf',
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'pdf_report'.tr(ref),
                    subtitle: 'pdf_report_desc'.tr(ref),
                    color: colors.incomeGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    context: context,
                    ref: ref,
                    id: 'csv',
                    icon: Icons.table_chart_outlined,
                    title: 'csv_excel'.tr(ref),
                    subtitle: 'csv_excel_desc'.tr(ref),
                    color: colors.profileInfo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    context: context,
                    ref: ref,
                    id: 'raw_csv',
                    icon: Icons.file_present_outlined,
                    title: 'raw_csv_report'.tr(ref),
                    subtitle: 'raw_csv_report_desc'.tr(ref),
                    color: colors.profileNotification,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = selectedType == id;
    final colors = context.colors;

    return GestureDetector(
      onTap: () => onTypeChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.incomeGreen
                : colors.textSecondary.withOpacity(0.08),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colors.incomeGreen.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
