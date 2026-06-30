import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/wallet/presentation/widget/shared/vnd_to_foreign_converter_bottom_sheet.dart';

class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.edit_note_rounded,
                label: 'manual_input'.tr(ref),
                iconColor: const Color(0xFF0D9488),
                onTap: () => context.push(RoutePaths.addTransaction),
              ),
            ),
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.swap_horiz_rounded,
                label: 'Transfer'.tr(ref),
                iconColor: const Color(0xFFEC4899),
                onTap: () => context.push(RoutePaths.wallet),
              ),
            ),
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.account_balance_wallet_rounded,
                label: 'add_wallet'.tr(ref),
                iconColor: const Color(0xFF14B8A6),
                onTap: () => context.push(RoutePaths.addWallet),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.category_rounded,
                label: 'Categories'.tr(ref),
                iconColor: const Color(0xFF10B981),
                onTap: () => context.push(RoutePaths.categories),
              ),
            ),
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.pie_chart_rounded,
                label: 'budget'.tr(ref),
                iconColor: const Color(0xFF3B82F6),
                onTap: () {
                  ref.read(selectedAnalyticTabProvider.notifier).state =
                      'budget';
                  context.go('${RoutePaths.analytics}?tab=budget');
                },
              ),
            ),
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.file_upload_outlined,
                label: 'export_title'.tr(ref),
                iconColor: const Color(0xFFEF4444),
                onTap: () => context.push(RoutePaths.export),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.currency_exchange_rounded,
                label: 'currency_exchange'.tr(ref),
                iconColor: const Color(0xFF8B5CF6),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      const VndToForeignConverterBottomSheet(),
                ),
              ),
            ),
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.autorenew_rounded,
                label: 'Schedule'.tr(ref),
                iconColor: const Color(0xFFF97316),
                onTap: () => context.push(RoutePaths.recurringList),
              ),
            ),
            Expanded(
              child: _buildQuickActionItem(
                context: context,
                icon: Icons.savings_rounded,
                label: 'savings_wallet_title'.tr(ref),
                iconColor: const Color(0xFFEC4899),
                onTap: () => context.push(RoutePaths.savingsList),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
