import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/presentation/providers/recurring_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/dashboard/presentation/screens/recurring_edit_screen.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_list/recurring_shimmer.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_list/recurring_list_summary_card.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_list/recurring_rule_card.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_list/recurring_list_helper.dart';

class RecurringListScreen extends ConsumerStatefulWidget {
  const RecurringListScreen({super.key});

  @override
  ConsumerState<RecurringListScreen> createState() =>
      _RecurringListScreenState();
}

class _RecurringListScreenState extends ConsumerState<RecurringListScreen> {
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'year'
  final Set<String> _executingRuleIds = {};

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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
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
            icon: Icon(
              Icons.add_circle_rounded,
              color: colors.primary,
              size: 28,
            ),
            onPressed: () => context
                .push(RoutePaths.recurringCreate)
                .then(
                  (_) => ref
                      .read(recurringNotifierProvider.notifier)
                      .refresh(silent: true),
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: recurringAsync.when(
        data: (rules) => _buildBody(context, ref, rules, colors),
        loading: () => const RecurringShimmer(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colors.expenseRed,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(e.toString(), style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(recurringNotifierProvider.notifier).refresh(),
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
        .fold<double>(
          0,
          (sum, r) =>
              sum +
              (r.amount * getOccurrencesInPeriod(r, now, _selectedPeriod)),
        );

    final activeCount = rules.where((r) => r.isActive).length;
    final inactiveCount = rules.where((r) => !r.isActive).length;

    // Đếm sắp đến hạn (next_run_at trong vòng 7 ngày)
    final upcomingCount = rules
        .where(
          (r) =>
              r.isActive &&
              r.nextRunAt != null &&
              r.nextRunAt!.isAfter(now) &&
              r.nextRunAt!.difference(now).inDays <= 7,
        )
        .length;

    // Đã thực hiện (đã chạy trong chu kỳ hiện tại)
    final executedCount = rules
        .where(
          (r) => r.isActive && (r.isExecutedCurrentPeriod || _isRuleRecordedToday(r)),
        )
        .length;

    return RefreshIndicator(
      onRefresh: () => ref.read(recurringNotifierProvider.notifier).refresh(),
      color: colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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

            // ── Summary Card
            RecurringListSummaryCard(
              totalThisPeriod: totalThisPeriod,
              executedCount: executedCount,
              upcomingCount: upcomingCount,
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (period) =>
                  setState(() => _selectedPeriod = period),
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
              ...rules.map(
                (rule) => RecurringRuleCard(
                  rule: rule,
                  isRecorded: _isRuleRecordedToday(rule),
                  isExecuting: _executingRuleIds.contains(rule.id),
                  onToggle: () => ref
                      .read(recurringNotifierProvider.notifier)
                      .toggleRule(rule.id),
                  onRecord: () => _executeRuleImmediately(context, ref, rule),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecurringEditScreen(rule: rule),
                    ),
                  ).then(
                    (_) => ref
                        .read(recurringNotifierProvider.notifier)
                        .refresh(silent: true),
                  ),
                ),
              ),
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
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: colors.primary,
                        size: 40,
                      ),
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
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .push(RoutePaths.recurringCreate)
                          .then(
                            (_) => ref
                                .read(recurringNotifierProvider.notifier)
                                .refresh(silent: true),
                          ),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        'recurring_add_first'.tr(ref),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _executeRuleImmediately(
    BuildContext context,
    WidgetRef ref,
    RecurringRuleEntity rule,
  ) async {
    setState(() {
      _executingRuleIds.add(rule.id);
    });

    final walletName = rule.walletName ?? '';
    final categoryName = rule.categoryName ?? '';
    final categoryId = rule.categoryId ?? '';

    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final currencyCode = rule.walletCurrencyCode ?? 'VND';

    final params = TransactionParams(
      walletId: rule.walletId,
      walletName: walletName,
      categoryId: rule.categoryId,
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
      sourceType: (rule.payeeId != null && rule.payeeId!.isNotEmpty)
          ? 'transfer'
          : 'recurring',
      sourceId: rule.id,
    );

    try {
      final transactionId = await ref
          .read(transactionListProvider.notifier)
          .addPendingTransaction(params, notify: false);

      // Handle custom notifications for recurring transactions
      final pref = ref.read(notificationPreferencesProvider).value;
      final showPush = pref?.pushEnabled ?? true;

      if (showPush) {
        final currentUserName =
            ref.read(currentUserProvider)?.fullName ?? 'Người dùng';
        final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);
        final formattedAmount =
            AppConstant.formatMoney(rule.amount, currencyCode);
        final walletPart = walletName.isNotEmpty ? ' ví "$walletName"' : '';

        // Creator Notification
        final isExpense = rule.type == 'expense';
        final creatorPrefix = isExpense ? '-' : '+';
        final creatorAction = isExpense ? 'từ' : 'vào';
        final creatorTitle = 'Giao dịch định kỳ';
        final creatorBody =
            '$creatorPrefix$formattedAmount $currencySymbol $creatorAction$walletPart. Nội dung: ${rule.title}';

        // Local Push Notification
        await LocalNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
          title: creatorTitle,
          body: creatorBody,
          payload: transactionId,
        );

        // In-app Notification for Creator
        final userId = ref.read(currentUserProvider)?.id ?? '';
        if (userId.isNotEmpty) {
          final localNotif = await LocalNotificationStorage.createAndSave(
            userId: userId,
            type: 'transaction',
            title: creatorTitle,
            body: creatorBody,
            metadata: {
              'transaction_id': transactionId,
              'amount': rule.amount,
              'wallet_name': walletName,
              'category_name': categoryName,
            },
          );
          if (localNotif != null) {
            ref
                .read(notificationNotifierProvider.notifier)
                .addLocalNotification(localNotif);
          }
        }

        // Payee Notification - if payee exists
        if (rule.payeeId != null && rule.payeeId!.isNotEmpty) {
          final payeeTitle = 'Nhận tiền định kỳ';
          final payeeBody =
              '+$formattedAmount $currencySymbol vào ví của bạn từ $currentUserName cho danh mục "$categoryName". Nội dung: ${rule.title}';

          // Local Push Notification for Payee (only show if current user is the payee)
          if (userId == rule.payeeId) {
            await LocalNotificationService.showNotification(
              id: (DateTime.now().millisecondsSinceEpoch + 1) & 0x7FFFFFFF,
              title: payeeTitle,
              body: payeeBody,
              payload: transactionId,
            );
          }

          // Save local in-app notification under payee's userId
          await LocalNotificationStorage.createAndSave(
            userId: rule.payeeId!,
            type: 'p2p_transfer',
            title: payeeTitle,
            body: payeeBody,
            metadata: {
              'transaction_id': transactionId,
              'amount': rule.amount,
              'sender_name': currentUserName,
              'category_name': categoryName,
            },
          );
        }
      }

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
                    'recurring_record_success'
                        .tr(ref)
                        .replaceFirst('{title}', rule.title),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981), // incomeGreen
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'recurring_record_failed'
                  .tr(ref)
                  .replaceFirst('{error}', e.toString()),
            ),
            backgroundColor: const Color(0xFFEF4444), // expenseRed
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _executingRuleIds.remove(rule.id);
        });
      }
    }
  }

  bool _isRuleRecordedToday(RecurringRuleEntity rule) {
    final transactionsAsync = ref.read(transactionListProvider);
    return transactionsAsync.maybeWhen(
      data: (transactions) {
        final user = ref.read(currentUserProvider);
        final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
        final location = tz.getLocation(tzName);

        final nowUser = tz.TZDateTime.now(location);
        final startOfToday =
            tz.TZDateTime(location, nowUser.year, nowUser.month, nowUser.day);
        final endOfToday = tz.TZDateTime(
            location, nowUser.year, nowUser.month, nowUser.day, 23, 59, 59);

        return transactions.any((tx) {
          final txDate =
              tz.TZDateTime.from(tx.transactionDate.toUtc(), location);
          final isSameDay =
              (txDate.isAfter(startOfToday) && txDate.isBefore(endOfToday)) ||
                  txDate.isAtSameMomentAs(startOfToday) ||
                  txDate.isAtSameMomentAs(endOfToday);

          if (!isSameDay) return false;

          // 1. Khớp theo sourceId (liên kết trực tiếp chính xác nhất)
          if (tx.sourceId == rule.id) return true;

          // 2. Khớp dự phòng theo tiêu đề, số tiền và ví (dành cho giao dịch offline/chờ đồng bộ)
          final isTitleMatch = tx.title == rule.title ||
              tx.title == 'Ghi nhận từ giao dịch định kỳ: ${rule.title}';
          final isAmountMatch = (tx.amountInUserCurrency - rule.amount).abs() < 0.01;
          final isWalletMatch = tx.walletId == rule.walletId;

          return isTitleMatch && isAmountMatch && isWalletMatch;
        });
      },
      orElse: () => false,
    );
  }
}
