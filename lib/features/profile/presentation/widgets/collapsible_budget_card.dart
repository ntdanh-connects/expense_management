import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class CollapsibleBudgetCard extends ConsumerWidget {
  final double spentAmount;
  final double totalAmount;

  const CollapsibleBudgetCard({
    super.key,
    required this.spentAmount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final double percent = totalAmount > 0 ? (spentAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
    final userCurrency = ref.watch(currentUserProvider)?.currency ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);

    return InkWell(
      onTap: () {
        ref.read(selectedAnalyticTabProvider.notifier).state = 'budget';
        context.go('${RoutePaths.analytics}?tab=budget');
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.authCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'this_month_budget'.tr(ref),
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (totalAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'spent_amount_info'.tr(ref)
                          .replaceAll('{spent}', AppConstant.formatMoney(spentAmount, userCurrency))
                          .replaceAll('{total}', AppConstant.formatMoney(totalAmount, userCurrency))} $currencySymbol',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: colors.profileBudgetProgress, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Thanh tiến trình ngân sách (Hình 2)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: colors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.profileBudgetProgress),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'no_overall_budget_setup'.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              // Greyed progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0,
                  minHeight: 10,
                  backgroundColor: colors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.textSecondary.withOpacity(0.2)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}