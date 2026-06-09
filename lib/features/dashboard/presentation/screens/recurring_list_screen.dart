import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/dashboard/presentation/screens/recurring_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/presentation/providers/recurring_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final recurringAsync = ref.watch(recurringNotifierProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'recurring_title'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: colors.primary, size: 28),
            onPressed: () => context.push(RoutePaths.recurringCreate).then((_) => ref.read(recurringNotifierProvider.notifier).refresh()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: recurringAsync.when(
        data: (rules) => _buildBody(context, ref, rules, colors),
        loading: () => const _RecurringShimmer(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.expenseRed, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(recurringNotifierProvider.notifier).refresh(),
                child: Text('try_again'.tr(ref)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<RecurringRuleEntity> rules,
    AppColorsExtension colors,
  ) {
    // Tính tổng chi tháng này (chỉ expense, isActive)
    final totalThisMonth = rules
        .where((r) => r.isActive && r.type == 'expense')
        .fold<double>(0, (sum, r) => sum + r.amount);

    final activeCount = rules.where((r) => r.isActive).length;
    final inactiveCount = rules.where((r) => !r.isActive).length;

    // Đếm sắp đến hạn (next_run_at trong vòng 7 ngày)
    final now = DateTime.now();
    final upcomingCount = rules
        .where((r) =>
            r.isActive &&
            r.nextRunAt != null &&
            r.nextRunAt!.isAfter(now) &&
            r.nextRunAt!.difference(now).inDays <= 7)
        .length;

    // Đã thực hiện (next_run_at trong quá khứ, isActive)
    final executedCount = rules
        .where((r) => r.isActive && r.nextRunAt != null && r.nextRunAt!.isBefore(now))
        .length;

    return RefreshIndicator(
      onRefresh: () => ref.read(recurringNotifierProvider.notifier).refresh(),
      color: colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tiêu đề + mô tả
            Text(
              'recurring_title'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'recurring_subtitle'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // ── Summary Card (xanh lá đậm)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B6B45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'recurring_total_month'.tr(ref).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppConstant.formatMoney(totalThisMonth, 'VND')} đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'recurring_executed'.tr(ref),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$executedCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'recurring_upcoming'.tr(ref),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$upcomingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Label ACTIVE SUBSCRIPTIONS + count chips
            if (rules.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'recurring_active_subs'.tr(ref).toUpperCase(),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      _buildCountChip(
                        '$activeCount ${'recurring_on'.tr(ref)}',
                        colors.primary.withOpacity(0.12),
                        colors.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildCountChip(
                        '$inactiveCount ${'recurring_off'.tr(ref)}',
                        colors.textSecondary.withOpacity(0.1),
                        colors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Danh sách rules
              ...rules.map((rule) => _buildRuleCard(context, ref, rule, colors)),
            ] else ...[
              // Empty state
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.autorenew_rounded, color: colors.primary, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'recurring_empty_title'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'recurring_empty_desc'.tr(ref),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push(RoutePaths.recurringCreate).then((_) => ref.read(recurringNotifierProvider.notifier).refresh()),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        'recurring_add_first'.tr(ref),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    WidgetRef ref,
    RecurringRuleEntity rule,
    AppColorsExtension colors,
  ) {
    final isExpense = rule.type == 'expense';
    final amountColor = isExpense ? colors.expenseRed : colors.incomeGreen;
    final sign = isExpense ? '-' : '+';
    final currencyCode = rule.walletCurrencyCode ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);

    // Lấy icon & màu danh mục
    final catIcon = CategoryUIConstants.getIconData(rule.categoryIcon, categoryName: rule.categoryName);
    final catColor = CategoryUIConstants.getColorFromHex(rule.categoryColor, categoryName: rule.categoryName);

    // Tính ngày kỳ tới
    String nextRunStr = '';
    if (rule.nextRunAt != null) {
      final d = rule.nextRunAt!;
      nextRunStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rule.isActive
              ? colors.textSecondary.withOpacity(0.06)
              : colors.textSecondary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Icon danh mục
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Title + frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rule.frequencyLabel,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Amount + next run
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${AppConstant.formatMoney(rule.amount, currencyCode)} $currencySymbol',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (nextRunStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Kỳ tới: $nextRunStr',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Bottom row: toggle + edit
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.textSecondary.withOpacity(0.06)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle
                GestureDetector(
                  onTap: () => ref.read(recurringNotifierProvider.notifier).toggleRule(rule.id),
                  child: Row(
                    children: [
                      Switch.adaptive(
                        value: rule.isActive,
                        activeColor: colors.primary,
                        activeTrackColor: colors.primary.withOpacity(0.3),
                        onChanged: (_) =>
                            ref.read(recurringNotifierProvider.notifier).toggleRule(rule.id),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rule.isActive ? 'recurring_active'.tr(ref) : 'recurring_inactive'.tr(ref),
                        style: TextStyle(
                          color: rule.isActive ? colors.primary : colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecurringEditScreen(rule: rule)),
                  ).then((_) => ref.read(recurringNotifierProvider.notifier).refresh()),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_outlined, color: colors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringShimmer extends StatelessWidget {
  const _RecurringShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 160, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            for (int i = 0; i < 4; i++) ...[
              Container(
                width: double.infinity,
                height: 100,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}