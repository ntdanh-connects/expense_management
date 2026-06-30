import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';

class BudgetCreateApplyTimeCard extends ConsumerWidget {
  final int selectedMonth;
  final int selectedYear;
  final bool copyFromPrevious;
  final VoidCallback onTapMonthYearPicker;
  final ValueChanged<bool> onCopyChanged;

  const BudgetCreateApplyTimeCard({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.copyFromPrevious,
    required this.onTapMonthYearPicker,
    required this.onCopyChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final locale = ref.watch(localeProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onTapMonthYearPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'apply_time'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        DateFormat.yMMMM(locale).format(DateTime(selectedYear, selectedMonth)),
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: colors.primary, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'copy_previous_desc'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(width: 8),
              Switch(
                value: copyFromPrevious,
                activeThumbColor: colors.primary,
                onChanged: onCopyChanged,
              ),
            ],
          )
        ],
      ),
    );
  }
}
