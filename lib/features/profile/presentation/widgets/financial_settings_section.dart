import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'profile_menu_item.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class FinancialSettingsSection extends ConsumerWidget {
  const FinancialSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    
    final budgetsAsync = ref.watch(currentMonthBudgetsProvider);
    final overallBudget = budgetsAsync.when(
      data: (list) => list.where((b) => b.categoryId == null).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'financial_settings'.tr(ref).toUpperCase(),
          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.authCardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ProfileMenuItem(
                icon: Icons.category_outlined,
                iconColor: colors.profileCategory,
                title: 'category_management'.tr(ref),
                onTap: () => context.push(RoutePaths.categories),
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.calendar_month_outlined,
                iconColor: colors.profileCalendar,
                title: 'financial_month'.tr(ref),
                onTap: () => context.push(RoutePaths.financialMonth),
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: colors.profileLimit,
                title: 'spending_limit'.tr(ref),
                trailingText: overallBudget != null
                    ? '${AppConstant.formatMoney(overallBudget.limitAmount, userCurrency)} $currencySymbol'
                    : null,
                onTap: () {
                  ref.read(selectedAnalyticTabProvider.notifier).state = 'budget';
                  context.go('${RoutePaths.analytics}?tab=budget');
                },
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.file_upload_outlined,
                iconColor: colors.profileInfo,
                title: 'export_report'.tr(ref),
                onTap: () => context.push(RoutePaths.export),
              ),
            ],
          ),
        ),
      ],
    );
  }
}