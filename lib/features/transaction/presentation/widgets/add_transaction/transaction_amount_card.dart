import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

class TransactionAmountCard extends ConsumerWidget {
  final TextEditingController amountController;
  final CurrencyTextInputFormatter formatter;
  final String? currencyCode;
  final bool isIncome;
  final String localeCode;

  const TransactionAmountCard({
    super.key,
    required this.amountController,
    required this.formatter,
    required this.currencyCode,
    required this.isIncome,
    required this.localeCode,
  });

  String _getCurrencySymbol(String? code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return 'đ';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: colors.authCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.textSecondary.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Text(
            'transaction_amount'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: isIncome ? colors.incomeGreen : colors.expenseRed,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: currencyCode != null
                  ? '0 ${_getCurrencySymbol(currencyCode)}'
                  : '0 đ',
              hintStyle: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: (isIncome ? colors.incomeGreen : colors.expenseRed)
                    .withOpacity(0.4),
              ),
            ),
            inputFormatters: [formatter],
            onChanged: (val) {
              final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
              final double? amt = double.tryParse(cleanString);
              if (amt != null && amt > 500000000) {
                final formatted = formatter.formatDouble(500000000);
                amountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: formatted.length),
                  ),
                );
              }
            },
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: amountController,
            builder: (context, value, child) {
              final currency = currencyCode ?? 'VND';
              if (currency != 'VND') {
                return const SizedBox.shrink();
              }
              final cleanString =
                  value.text.replaceAll(RegExp(r'[^0-9]'), '');
              final double? amt = double.tryParse(cleanString);
              if (amt == null || amt == 0) {
                return const SizedBox.shrink();
              }
              final wordRepresentation =
                  formatNumberToWords(amt, localeCode);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '($wordRepresentation)',
                  textAlign: TextAlign.center,
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
      ),
    );
  }
}
