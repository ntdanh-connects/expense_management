import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class TransactionHistoryTypeChip extends ConsumerWidget {
  final String label;
  final String value;

  const TransactionHistoryTypeChip({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(transactionFilterProvider);
    final isSelected = (value == 'All' && filter.type == null) ||
        (value.toLowerCase() == filter.type?.toLowerCase());

    return GestureDetector(
      onTap: () {
        ref.read(transactionFilterProvider.notifier).update(
              (state) => state.copyWith(
                type: value == 'All' ? null : value.toLowerCase(),
                clearType: value == 'All',
              ),
            );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.textSecondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
