import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class BudgetEditLimitSettingCard extends ConsumerWidget {
  final TextEditingController amountController;
  final bool isReadOnly;
  final CurrencyTextInputFormatter formatter;
  final String currencySymbol;
  final String userCurrency;
  final double threshold80Amount;
  final bool alert80;
  final bool alert100;
  final ValueChanged<bool>? onAlert80Changed;
  final ValueChanged<bool>? onAlert100Changed;
  final ValueChanged<String> onAmountChanged;

  const BudgetEditLimitSettingCard({
    super.key,
    required this.amountController,
    required this.isReadOnly,
    required this.formatter,
    required this.currencySymbol,
    required this.userCurrency,
    required this.threshold80Amount,
    required this.alert80,
    required this.alert100,
    required this.onAlert80Changed,
    required this.onAlert100Changed,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'monthly_limit'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            enabled: !isReadOnly,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.3)),
              suffixText: currencySymbol,
              suffixStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.primary, width: 1.2),
              ),
            ),
            inputFormatters: [formatter],
            onChanged: onAmountChanged,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'please_enter_limit'.tr(ref);
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Divider(color: colors.textSecondary.withOpacity(0.08)),
          const SizedBox(height: 12),

          // Switch Cảnh báo 80%
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'alert_80_title'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'alert_80_desc_format'.tr(ref).replaceAll('{amount}', '${AppConstant.formatMoney(threshold80Amount, userCurrency)} $currencySymbol'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: alert80,
                activeThumbColor: colors.primary,
                onChanged: onAlert80Changed,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Switch Cảnh báo 100%
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'alert_100_title'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'alert_100_desc'.tr(ref),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: alert100,
                activeThumbColor: colors.primary,
                onChanged: onAlert100Changed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
