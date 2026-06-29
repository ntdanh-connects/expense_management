import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class RecurringBeneficiaryTile extends ConsumerWidget {
  final Map<String, dynamic>? selectedPayee;
  final String? recipientWalletName;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const RecurringBeneficiaryTile({
    super.key,
    required this.selectedPayee,
    required this.recipientWalletName,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: selectedPayee == null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline_rounded,
                        color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'recurring_select_payee'.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: colors.textSecondary.withOpacity(0.5)),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selectedPayee!['payee_type'] == 'bank'
                          ? Icons.account_balance_rounded
                          : selectedPayee!['payee_type'] == 'p2p'
                              ? Icons.person_rounded
                              : Icons.qr_code_scanner_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPayee!['payee_name'] ?? '',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          selectedPayee!['payee_type'] == 'bank'
                              ? '${selectedPayee!['bank_name']} - ${selectedPayee!['identifier']}'
                              : '${selectedPayee!['identifier']}',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
                        ),
                        if ((selectedPayee!['payee_type'] == 'internal' ||
                                selectedPayee!['payee_type'] == 'p2p') &&
                            recipientWalletName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ví nhận: $recipientWalletName',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      onClear();
                    },
                    child: Icon(Icons.cancel_rounded,
                        color: colors.textSecondary, size: 20),
                  ),
                ],
              ),
      ),
    );
  }
}
