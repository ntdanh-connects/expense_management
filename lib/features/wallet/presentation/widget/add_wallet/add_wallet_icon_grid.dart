import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import '../shared/wallet_constants.dart';

class AddWalletIconGrid extends ConsumerWidget {
  final String selectedIcon;
  final ValueChanged<String> onIconSelected;

  const AddWalletIconGrid({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_icon'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: WalletUIConstants.iconsList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final item = WalletUIConstants.iconsList[index];
            final String key = item['key'];
            final IconData iconData = item['icon'];
            final isSelected = selectedIcon == key;

            return GestureDetector(
              onTap: () => onIconSelected(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withOpacity(0.12)
                      : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? colors.primary : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  iconData,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: 22,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
