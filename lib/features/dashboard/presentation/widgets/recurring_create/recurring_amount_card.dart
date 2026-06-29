import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class RecurringAmountCard extends ConsumerWidget {
  final TextEditingController titleController;
  final CurrencyTextInputFormatter formatter;
  final String? currencyCode;
  final String selectedType;

  const RecurringAmountCard({
    super.key,
    required this.titleController,
    required this.formatter,
    required this.currencyCode,
    required this.selectedType,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountColor = colors.expenseRed;

    return Container(
      decoration: BoxDecoration(
        color: amountColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: amountColor.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'recurring_amount_label'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _getCurrencySymbol(currencyCode),
                style: TextStyle(
                  color: amountColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: amountColor.withOpacity(0.4),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  inputFormatters: [formatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: colors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'recurring_title_hint'.tr(ref),
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.5),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
