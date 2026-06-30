import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import '../shared/wallet_constants.dart';

class AddWalletColorPicker extends ConsumerWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const AddWalletColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_color'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: WalletUIConstants.colorsList.length,
            itemBuilder: (context, idx) {
              final c = WalletUIConstants.colorsList[idx];
              final hex = c['hex']!;
              final isSelected = selectedColor == hex;
              final colorVal = Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));

              return GestureDetector(
                onTap: () => onColorSelected(hex),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorVal,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : colors.textPrimary,
                            width: 3.0,
                          )
                        : Border.all(color: Colors.transparent),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: colorVal.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
