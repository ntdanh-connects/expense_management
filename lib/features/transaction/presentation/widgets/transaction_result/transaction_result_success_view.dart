import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/animated_checkmark.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/dotted_line.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

class TransactionResultSuccessView extends ConsumerWidget {
  final TransactionParams params;
  final String? transactionId;
  final String? finalTitle;
  final String? finalCategoryName;
  final String formattedAmount;
  final String formattedDate;
  final VoidCallback onCreateNewTransaction;
  final VoidCallback onMainScreen;

  const TransactionResultSuccessView({
    super.key,
    required this.params,
    required this.transactionId,
    required this.finalTitle,
    required this.finalCategoryName,
    required this.formattedAmount,
    required this.formattedDate,
    required this.onCreateNewTransaction,
    required this.onMainScreen,
  });

  Widget _buildReceiptRow(
    BuildContext context,
    AppColorsExtension colors,
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: 14,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);
    final isIncome = params.type == 'income';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const AnimatedCheckmark(isSuccess: true),
                    const SizedBox(height: 20),
                    Text(
                      'save_transaction_success'.tr(ref),
                      style: TextStyle(
                        color: colors.incomeGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  formattedAmount,
                                  style: TextStyle(
                                    color: isIncome ? colors.incomeGreen : colors.expenseRed,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (params.currencyCode == 'VND' || params.currencyCode.isEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '(${formatNumberToWords(params.amount, localeCode)})',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  (finalTitle != null && finalTitle!.isNotEmpty)
                                      ? finalTitle!
                                      : (params.title.isNotEmpty
                                          ? params.title
                                          : (params.categoryName ?? 'uncategorized'.tr(ref))),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: DottedLine(
                              color: colors.textSecondary.withOpacity(0.2),
                              height: 1.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'transaction_type'.tr(ref),
                                  isIncome ? 'income'.tr(ref) : 'expense'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'category_label'.tr(ref),
                                  finalCategoryName ?? params.categoryName ?? 'uncategorized'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'payment_wallet'.tr(ref),
                                  params.walletName,
                                ),
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'transaction_time'.tr(ref),
                                  formattedDate,
                                ),
                                if (transactionId != null)
                                  _buildReceiptRow(
                                    context,
                                    colors,
                                    'transaction_code'.tr(ref),
                                    transactionId!,
                                  ),
                                if (params.notes != null && params.notes!.isNotEmpty)
                                  _buildReceiptRow(
                                    context,
                                    colors,
                                    'description'.tr(ref),
                                    params.notes!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCreateNewTransaction,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'create_new_gd'.tr(ref),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onMainScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'main_screen'.tr(ref),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
