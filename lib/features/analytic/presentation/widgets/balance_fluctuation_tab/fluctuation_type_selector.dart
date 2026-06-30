import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class FluctuationTypeSelector extends StatelessWidget {
  final String typeMode;
  final ValueChanged<String> onTypeModeChanged;

  const FluctuationTypeSelector({
    super.key,
    required this.typeMode,
    required this.onTypeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tabs = {
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'difference': 'Chênh lệch',
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
