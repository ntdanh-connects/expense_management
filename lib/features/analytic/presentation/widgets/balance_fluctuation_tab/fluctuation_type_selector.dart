import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class FluctuationTypeSelector extends ConsumerWidget {
  final String typeMode;
  final ValueChanged<String> onTypeModeChanged;

  const FluctuationTypeSelector({
    super.key,
    required this.typeMode,
    required this.onTypeModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tabs = {
      'income': 'income'.tr(ref),
      'expense': 'expense'.tr(ref),
      'difference': 'difference'.tr(ref),
    };

    return Row(
      children: tabs.keys.map((key) {
        final isSelected = typeMode == key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTypeModeChanged(key),
            child: Column(
              children: [
                Text(
                  tabs[key]!,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
