import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

class SandboxAmountInput extends StatelessWidget {
  final TextEditingController amountController;
  final String localeCode;

  const SandboxAmountInput({
    super.key,
    required this.amountController,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số tiền nhận (VND)'.toUpperCase(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: 'Nhập số tiền nạp...',
              border: InputBorder.none,
            ),
            onChanged: (val) {
              if (val.isEmpty) return;
              final cleanString = val.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              double? amt = double.tryParse(cleanString);
              if (amt != null) {
                if (amt > 500000000) {
                  amt = 500000000;
                }
                final formatted = NumberFormat(
                  '#,###',
                  'vi_VN',
                ).format(amt);
                amountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: formatted.length),
                  ),
                );
              }
            },
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: amountController,
          builder: (context, value, child) {
            final cleanString = value.text.replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );
            final double? amt = double.tryParse(cleanString);
            if (amt == null || amt == 0) {
              return const SizedBox.shrink();
            }
            final wordRepresentation = formatNumberToWords(
              amt,
              localeCode,
            );
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                '($wordRepresentation)',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
