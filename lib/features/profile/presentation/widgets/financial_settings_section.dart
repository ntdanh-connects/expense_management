import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'profile_menu_item.dart';

class FinancialSettingsSection extends ConsumerWidget {
  const FinancialSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

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
                onTap: () {},
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: colors.profileLimit,
                title: 'spending_limit'.tr(ref),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}