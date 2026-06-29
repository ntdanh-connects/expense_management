import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class TransactionHistoryAmountRangeDialog extends ConsumerStatefulWidget {
  const TransactionHistoryAmountRangeDialog({super.key});

  @override
  ConsumerState<TransactionHistoryAmountRangeDialog> createState() =>
      _TransactionHistoryAmountRangeDialogState();
}

class _TransactionHistoryAmountRangeDialogState
    extends ConsumerState<TransactionHistoryAmountRangeDialog> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterProvider);
    _minController = TextEditingController(
      text: filter.minAmount != null ? filter.minAmount!.toStringAsFixed(0) : '',
    );
    _maxController = TextEditingController(
      text: filter.maxAmount != null ? filter.maxAmount!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Lọc khoảng số tiền',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _minController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Số tiền tối thiểu',
              labelStyle: TextStyle(color: colors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Số tiền tối đa',
              labelStyle: TextStyle(color: colors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(transactionFilterProvider.notifier).update(
                  (state) => state.copyWith(clearAmount: true),
                );
            Navigator.pop(context);
          },
          child: Text('Xoá lọc', style: TextStyle(color: colors.expenseRed)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Huỷ', style: TextStyle(color: colors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final minVal = double.tryParse(_minController.text.trim());
            final maxVal = double.tryParse(_maxController.text.trim());
            ref.read(transactionFilterProvider.notifier).update(
                  (state) => state.copyWith(
                    minAmount: minVal,
                    maxAmount: maxVal,
                    clearAmount: minVal == null && maxVal == null,
                  ),
                );
            Navigator.pop(context);
          },
          child: Text(
            'Áp dụng',
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
