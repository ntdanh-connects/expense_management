import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class TransactionHistorySortSheet extends ConsumerWidget {
  const TransactionHistorySortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(transactionFilterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Sắp xếp theo',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            RadioListTile<String>(
              title: Text('Ngày giao dịch', style: TextStyle(color: colors.textPrimary)),
              value: 'date',
              groupValue: filter.sortBy,
              activeColor: colors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(transactionFilterProvider.notifier).update(
                        (state) => state.copyWith(sortBy: val),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: Text('Số tiền', style: TextStyle(color: colors.textPrimary)),
              value: 'amount',
              groupValue: filter.sortBy,
              activeColor: colors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(transactionFilterProvider.notifier).update(
                        (state) => state.copyWith(sortBy: val),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: Text('Danh mục', style: TextStyle(color: colors.textPrimary)),
              value: 'category',
              groupValue: filter.sortBy,
              activeColor: colors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(transactionFilterProvider.notifier).update(
                        (state) => state.copyWith(sortBy: val),
                      );
                }
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Thứ tự sắp xếp',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            RadioListTile<String>(
              title: Text('Giảm dần (Mới nhất/Lớn nhất/A-Z)', style: TextStyle(color: colors.textPrimary)),
              value: 'desc',
              groupValue: filter.sortOrder,
              activeColor: colors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(transactionFilterProvider.notifier).update(
                        (state) => state.copyWith(sortOrder: val),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: Text('Tăng dần (Cũ nhất/Nhỏ nhất/Z-A)', style: TextStyle(color: colors.textPrimary)),
              value: 'asc',
              groupValue: filter.sortOrder,
              activeColor: colors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(transactionFilterProvider.notifier).update(
                        (state) => state.copyWith(sortOrder: val),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
