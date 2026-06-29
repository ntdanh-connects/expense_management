import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/animated_checkmark.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionResultFailureView extends ConsumerWidget {
  final String? errorMessage;
  final VoidCallback onBackToEdit;
  final VoidCallback onRetry;

  const TransactionResultFailureView({
    super.key,
    required this.errorMessage,
    required this.onBackToEdit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const AnimatedCheckmark(isSuccess: false),
            const SizedBox(height: 24),
            Text(
              'transaction_failed'.tr(ref),
              style: TextStyle(
                color: colors.expenseRed,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.expenseRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.expenseRed.withOpacity(0.15)),
              ),
              child: Text(
                errorMessage ?? 'unknown_error'.tr(ref),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.expenseRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBackToEdit,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colors.textSecondary.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'back_to_edit'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'retry'.tr(ref),
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
