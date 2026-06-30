import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class AddWalletTypeSelector extends ConsumerWidget {
  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  const AddWalletTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_wallet_type'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildTypeChip(
              context: context,
              ref: ref,
              key: 'cash',
              label: 'wallet_type_cash'.tr(ref),
              icon: Icons.payments_rounded,
              colors: colors,
            ),
            const SizedBox(width: 10),
            _buildTypeChip(
              context: context,
              ref: ref,
              key: 'bank',
              label: 'wallet_type_bank'.tr(ref),
              icon: Icons.account_balance_rounded,
              colors: colors,
            ),
            const SizedBox(width: 10),
            _buildTypeChip(
              context: context,
              ref: ref,
              key: 'e-wallet',
              label: 'wallet_type_ewallet'.tr(ref),
              icon: Icons.qr_code_scanner_rounded,
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required BuildContext context,
    required WidgetRef ref,
    required String key,
    required String label,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    final isSelected = selectedType == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeSelected(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
