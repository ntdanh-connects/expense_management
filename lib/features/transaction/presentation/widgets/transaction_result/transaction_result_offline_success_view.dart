import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/dotted_line.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

class TransactionResultOfflineSuccessView extends ConsumerWidget {
  final TransactionParams params;
  final String formattedAmount;
  final String formattedDate;
  final VoidCallback onCreateNewTransaction;
  final VoidCallback onMainScreen;

  const TransactionResultOfflineSuccessView({
    super.key,
    required this.params,
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
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'offline_mode_title'.tr(ref),
                      style: const TextStyle(
                        color: Colors.orange,
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
                                    '(${formatNumberToWords(params.amount ?? 0.0, localeCode)})',
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
                                  params.title.isNotEmpty
                                      ? params.title
                                      : (params.categoryName ?? 'uncategorized'.tr(ref)),
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
                                  params.categoryName ?? 'uncategorized'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'payment_wallet'.tr(ref),
                                  params.walletName ?? '',
                                ),
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'transaction_time'.tr(ref),
                                  formattedDate,
                                ),
                                _buildReceiptRow(
                                  context,
                                  colors,
                                  'transaction_code'.tr(ref),
                                  'transaction_status_pending'.tr(ref),
                                  valueColor: Colors.orange,
                                  isBoldValue: true,
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
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'save_transaction_offline'.tr(ref),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
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
