import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_provider.dart';

class FluctuationTimeSelector extends ConsumerWidget {
  final String timeMode;
  final ValueChanged<String> onTimeModeChanged;

  const FluctuationTimeSelector({
    super.key,
    required this.timeMode,
    required this.onTimeModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isEnglish = ref.watch(localeProvider) == 'en';
    final tabs = {
      'week': isEnglish ? 'Weekly' : 'Theo tuần',
      'month': isEnglish ? 'Monthly' : 'Theo tháng',
      'year': isEnglish ? 'Yearly' : 'Theo năm',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs.keys.map((key) {
          final isSelected = timeMode == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTimeModeChanged(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tabs[key]!,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
