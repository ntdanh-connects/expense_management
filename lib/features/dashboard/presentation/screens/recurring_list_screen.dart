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
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/profile/user_provider.dart';

class RecurringListScreen extends ConsumerStatefulWidget {
  const RecurringListScreen({super.key});

  @override
  ConsumerState<RecurringListScreen> createState() => _RecurringListScreenState();
}

class _RecurringListScreenState extends ConsumerState<RecurringListScreen> {
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'year'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recurringAsync = ref.watch(recurringNotifierProvider);
    ref.watch(transactionListProvider);

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
            onPressed: () => context.push(RoutePaths.recurringCreate).then((_) => ref.read(recurringNotifierProvider.notifier).refresh(silent: true)),
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
    final now = DateTime.now();

    // Tính tổng chi định kỳ (chỉ expense, isActive, theo khoảng thời gian được chọn)
    final totalThisPeriod = rules
        .where((r) => r.isActive && r.type == 'expense')
        .fold<double>(0, (sum, r) => sum + (r.amount * _getOccurrencesInPeriod(r, now, _selectedPeriod)));

    final activeCount = rules.where((r) => r.isActive).length;
    final inactiveCount = rules.where((r) => !r.isActive).length;

    // Đếm sắp đến hạn (next_run_at trong vòng 7 ngày)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getPeriodTotalTitleKey(_selectedPeriod).tr(ref).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPeriodTab('day', 'recurring_day'.tr(ref)),
                            _buildPeriodTab('week', 'recurring_week'.tr(ref)),
                            _buildPeriodTab('month', 'recurring_month'.tr(ref)),
                            _buildPeriodTab('year', 'recurring_year'.tr(ref)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppConstant.formatMoney(totalThisPeriod, 'VND')} đ',
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
                      onPressed: () => context.push(RoutePaths.recurringCreate).then((_) => ref.read(recurringNotifierProvider.notifier).refresh(silent: true)),
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
                        'recurring_label_${rule.frequency}'.tr(ref),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      if (rule.payeeName != null && rule.payeeName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, color: colors.textSecondary, size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rule.payeeName!,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        '${'recurring_next_run'.tr(ref)}: $nextRunStr',
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
                Row(
                  children: [
                    Switch.adaptive(
                      value: rule.isActive,
                      activeColor: colors.primary,
                      activeTrackColor: colors.primary.withOpacity(0.3),
                      onChanged: (_) =>
                          ref.read(recurringNotifierProvider.notifier).toggleRule(rule.id),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => ref.read(recurringNotifierProvider.notifier).toggleRule(rule.id),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Text(
                          rule.isActive ? 'recurring_active'.tr(ref) : 'recurring_inactive'.tr(ref),
                          style: TextStyle(
                            color: rule.isActive ? colors.primary : colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Actions: Ghi nhận ngay + Edit
                Row(
                  children: [
                    (() {
                      final isRecorded = _isRuleRecordedToday(rule);
                      final isEnabled = rule.isActive && !isRecorded;
                      return GestureDetector(
                        onTap: isEnabled
                            ? () => _executeRuleImmediately(context, ref, rule)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: !isEnabled
                                ? colors.textSecondary.withOpacity(0.06)
                                : colors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !isEnabled
                                  ? Colors.transparent
                                  : colors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isRecorded
                                    ? Icons.check_circle_rounded
                                    : Icons.add_task_rounded,
                                color: !isEnabled
                                    ? colors.textSecondary
                                    : colors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isRecorded ? 'recurring_recorded'.tr(ref) : 'recurring_record'.tr(ref),
                                style: TextStyle(
                                  color: !isEnabled
                                      ? colors.textSecondary
                                      : colors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })(),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RecurringEditScreen(rule: rule)),
                      ).then((_) => ref.read(recurringNotifierProvider.notifier).refresh(silent: true)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getOccurrencesInPeriod(RecurringRuleEntity rule, DateTime now, String period) {
    if (!rule.isActive) return 0;

    DateTime start;
    DateTime end;

    switch (period) {
      case 'day':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        final daysToSubtract = now.weekday - 1;
        start = DateTime(now.year, now.month, now.day - daysToSubtract);
        end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    final ruleStart = rule.startDate ?? start;

    if (ruleStart.isAfter(end)) return 0;
    if (rule.endAt != null && rule.endAt!.isBefore(start)) return 0;

    int count = 0;
    DateTime current = ruleStart;
    final interval = rule.intervalValue > 0 ? rule.intervalValue : 1;

    switch (rule.frequency) {
      case 'daily':
        if (current.isBefore(start)) {
          final differenceInDays = start.difference(current).inDays;
          final skipIntervals = differenceInDays ~/ interval;
          current = current.add(Duration(days: skipIntervals * interval));
          while (current.isBefore(start)) {
            current = current.add(Duration(days: interval));
          }
        }
        break;
      case 'weekly':
        if (current.isBefore(start)) {
          final differenceInDays = start.difference(current).inDays;
          final skipIntervals = differenceInDays ~/ (7 * interval);
          current = current.add(Duration(days: skipIntervals * 7 * interval));
          while (current.isBefore(start)) {
            current = current.add(Duration(days: 7 * interval));
          }
        }
        break;
      case 'monthly':
        if (current.isBefore(start)) {
          int monthsDiff = (start.year - current.year) * 12 + (start.month - current.month);
          int skipIntervals = monthsDiff ~/ interval;
          current = DateTime(
            current.year + (current.month + skipIntervals * interval - 1) ~/ 12,
            (current.month + skipIntervals * interval - 1) % 12 + 1,
            current.day,
          );
          while (current.isBefore(start)) {
            current = DateTime(current.year, current.month + interval, current.day);
          }
        }
        break;
      case 'yearly':
        if (current.isBefore(start)) {
          int yearsDiff = start.year - current.year;
          int skipIntervals = yearsDiff ~/ interval;
          current = DateTime(current.year + skipIntervals * interval, current.month, current.day);
          while (current.isBefore(start)) {
            current = DateTime(current.year + interval, current.month, current.day);
          }
        }
        break;
    }

    int maxLoopCount = 366;
    if (period == 'day') maxLoopCount = 2;
    if (period == 'week') maxLoopCount = 8;
    if (period == 'month') maxLoopCount = 32;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (rule.endAt != null && current.isAfter(rule.endAt!)) {
        break;
      }
      if (current.isAfter(start) || current.isAtSameMomentAs(start)) {
        count++;
      }

      switch (rule.frequency) {
        case 'daily':
          current = current.add(Duration(days: interval));
          break;
        case 'weekly':
          current = current.add(Duration(days: 7 * interval));
          break;
        case 'monthly':
          current = DateTime(current.year, current.month + interval, current.day);
          break;
        case 'yearly':
          current = DateTime(current.year + interval, current.month, current.day);
          break;
        default:
          return count;
      }

      if (count > maxLoopCount) break;
    }

    return count;
  }

  String _getPeriodTotalTitleKey(String period) {
    switch (period) {
      case 'day':
        return 'recurring_total_day';
      case 'week':
        return 'recurring_total_week';
      case 'month':
        return 'recurring_total_month';
      case 'year':
        return 'recurring_total_year';
      default:
        return 'recurring_total_month';
    }
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1B6B45) : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _executeRuleImmediately(BuildContext context, WidgetRef ref, RecurringRuleEntity rule) async {
    final walletName = rule.walletName ?? '';
    final categoryName = rule.categoryName ?? '';
    final categoryId = rule.categoryId ?? '';

    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final currencyCode = rule.walletCurrencyCode ?? 'VND';

    final params = TransactionParams(
      walletId: rule.walletId,
      walletName: walletName,
      categoryId: categoryId,
      categoryName: categoryName,
      type: rule.type,
      amount: rule.amount,
      title: rule.title,
      notes: 'Ghi nhận từ giao dịch định kỳ: ${rule.title}',
      transactionDate: DateTime.now().toUtc().toIso8601String(),
      currencyCode: currencyCode,
      exchangeRate: 1.0,
      timezone: tzName,
      payeeId: rule.payeeId,
      payeeName: rule.payeeName,
      payeeAccountNumber: rule.payeeAccountNumber,
      payeeBankName: rule.payeeBankName,
    );

    try {
      await ref.read(transactionListProvider.notifier).addPendingTransaction(params);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'recurring_record_success'.tr(ref).replaceFirst('{title}', rule.title),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981), // incomeGreen
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recurring_record_failed'.tr(ref).replaceFirst('{error}', e.toString())),
            backgroundColor: const Color(0xFFEF4444), // expenseRed
          ),
        );
      }
    }
  }

  bool _isRuleRecordedToday(RecurringRuleEntity rule) {
    final transactionsAsync = ref.read(transactionListProvider);
    return transactionsAsync.maybeWhen(
      data: (transactions) {
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

        return transactions.any((tx) {
          final txDate = tx.transactionDate.toLocal();
          final isSameDay = (txDate.isAfter(startOfToday) && txDate.isBefore(endOfToday)) ||
              txDate.isAtSameMomentAs(startOfToday) ||
              txDate.isAtSameMomentAs(endOfToday);

          return isSameDay &&
              tx.title == rule.title &&
              tx.amount == rule.amount &&
              tx.walletId == rule.walletId &&
              tx.categoryId == rule.categoryId;
        });
      },
      orElse: () => false,
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