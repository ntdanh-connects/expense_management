import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';

class BudgetEmptyOverallCard extends ConsumerWidget {
  final bool isPastMonth;

  const BudgetEmptyOverallCard({
    super.key,
    required this.isPastMonth,
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
        border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 48, color: colors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            isPastMonth 
                ? 'no_overall_budget_history'.tr(ref)
                : 'no_overall_budget_setup'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isPastMonth) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                  ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                }),
                child: Text(
                  'setup_overall_budget_now'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
