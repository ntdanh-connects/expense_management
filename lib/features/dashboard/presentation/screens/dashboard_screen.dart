import 'package:expense_management/core/router/app_route.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/shared/widgets/transaction_list_shimmer.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';

final showBalanceProvider = StateProvider<bool>((ref) => true);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final walletState = ref.watch(walletNotifierProvider);
    final showBalance = ref.watch(showBalanceProvider);
    final transactionState = ref.watch(transactionListProvider);

    final userCurrency = ref.watch(currentUserProvider)?.currency ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;

    const fallbackRates = {
      'USD': 1.0,
      'VND': 25400.0,
      'EUR': 0.92,
      'GBP': 0.78,
      'JPY': 156.0,
    };

    double convertCurrency(double balance, String walletCurrency) {
      final String wCurr = walletCurrency.toUpperCase();
      final String uCurr = userCurrency.toUpperCase();
      if (wCurr == uCurr) return balance;
      final base = (ratesData?.base ?? 'USD').toUpperCase();
      final rates = ratesData?.rates.map((k, v) => MapEntry(k.toUpperCase(), v.toDouble())) ?? fallbackRates;
      final fromRate = wCurr == base ? 1.0 : (rates[wCurr] ?? 1.0);
      final toRate = uCurr == base ? 1.0 : (rates[uCurr] ?? 1.0);
      return balance * (toRate / fromRate);
    }

    final totalBalanceStr = walletState.when(
      data: (walletList) {
        final visibleWallets = walletList.where((w) => !w.isHidden).toList();
        final totalBalance = visibleWallets.fold<double>(0, (sum, w) {
          return sum + convertCurrency(w.balance, w.currencyCode);
        });
        return showBalance
            ? '${AppConstant.formatMoney(totalBalance, userCurrency)} $currencySymbol'
            : '•••••• $currencySymbol';
      },
      loading: () => '... $currencySymbol',
      error: (_, __) => '0 $currencySymbol',
    );

    final dashboardSummary = ref.watch(dashboardSummaryProvider);

    final monthlyIncomeStr = dashboardSummary.when(
      data: (summary) => showBalance
          ? '+${AppConstant.formatMoney(summary.income, userCurrency)} $currencySymbol'
          : '•••••• $currencySymbol',
      loading: () => '...',
      error: (_, __) => '0 $currencySymbol',
    );

    final monthlyExpenseStr = dashboardSummary.when(
      data: (summary) => showBalance
          ? '-${AppConstant.formatMoney(summary.expense, userCurrency)} $currencySymbol'
          : '•••••• $currencySymbol',
      loading: () => '...',
      error: (_, __) => '0 $currencySymbol',
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(
        hintText: 'search_hint'.tr(ref),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletNotifierProvider.notifier).refreshWallets();
          await ref.read(transactionListProvider.notifier).refreshTransactions(silent: true);
          ref.invalidate(dashboardSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💳 1. TỔNG SỐ DƯ CARD (XANH/TÍM GRADIENT HỆ THỐNG)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'total_balance'.tr(ref),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            ref.read(showBalanceProvider.notifier).update((state) => !state);
                          },
                          child: Icon(
                            ref.watch(showBalanceProvider)
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalBalanceStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Khoản thu nhập
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.greenAccent,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'income_label'.tr(ref),
                                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      monthlyIncomeStr,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Khoản chi tiêu
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.redAccent,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'expense_label'.tr(ref),
                                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      monthlyExpenseStr,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
              const SizedBox(height: 24),
  
              // 💼 2. VÍ CỦA BẠN ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'wallets'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/wallet');
                    },
                    child: Text(
                      'see_all'.tr(ref),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
  
               // DANH SÁCH VÍ HÀNG NGANG (SCROLL HORIZONTAL)
              SizedBox(
                height: 110,
                child: walletState.when(
                  data: (walletList) {
                    final visibleWallets = walletList.where((w) => !w.isHidden).toList();
                    if (visibleWallets.isEmpty) {
                      return Center(
                        child: Text(
                          'no_wallets'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleWallets.length,
                      itemBuilder: (context, index) {
                        final wallet = visibleWallets[index];
                        final hexColor = wallet.color.replaceAll('#', '');
                        Color itemColor;
                        try {
                          itemColor = hexColor.length == 6
                              ? Color(int.parse('FF$hexColor', radix: 16))
                              : colors.primary;
                        } catch (_) {
                          itemColor = colors.primary;
                        }
  
                        final showBalance = ref.watch(showBalanceProvider);
  
                        return _buildWalletCard(
                          context: context,
                          title: wallet.name,
                          amount: showBalance 
                              ? '${AppConstant.formatMoney(wallet.balance, wallet.currencyCode)} ${wallet.currencyCode}' 
                              : '•••••• ${wallet.currencyCode}',
                          icon: _getWalletIcon(wallet.type),
                          iconBgColor: itemColor.withOpacity(0.12),
                          iconColor: itemColor,
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      '${'load_wallets_error'.tr(ref)}: $err',
                      style: TextStyle(color: colors.expenseRed, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
  
              // THANH PHÍM TẮT MOMO-STYLE (QUICK ACTIONS)
              Text(
                'Features'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'qr_transfer'.tr(ref),
                            iconColor: const Color(0xFF0D9488),
                            onTap: () => context.push('/qr-scanner'),
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
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.category_rounded,
                            label: 'Categories'.tr(ref),
                            iconColor: const Color(0xFF10B981),
                            onTap: () => context.push(RoutePaths.categories),
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
                            icon: Icons.pie_chart_rounded,
                            label: 'budget'.tr(ref),
                            iconColor: const Color(0xFF3B82F6),
                            onTap: () {
                              ref.read(selectedAnalyticTabProvider.notifier).state = 'budget';
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
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.bar_chart_rounded,
                            label: 'statistics'.tr(ref),
                            iconColor: const Color(0xFF8B5CF6),
                            onTap: () => context.go(RoutePaths.analytics),
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
  
              // 🧾 3. GIAO DỊCH GẦN ĐÂY ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'recent_transactions'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(RoutePaths.history, extra: 'recent');
                    },
                    child: Row(
                      children: [
                        Text(
                          'see_all'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: colors.primary, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
  
              // DANH SÁCH GIAO DỊCH GẦN ĐÂY (5 giao dịch mới nhất)
              ref.watch(transactionListProvider).when(
                data: (txList) {
                  if (txList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Chưa có giao dịch nào.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    );
                  }
  
                  // Sắp xếp: Ưu tiên giao dịch chờ đồng bộ (pending) lên đầu, sau đó sắp xếp theo ngày mới nhất
                  final sorted = [...txList]
                    ..sort((a, b) {
                      final aPending = a.status == 'pending';
                      final bPending = b.status == 'pending';
                      if (aPending && !bPending) return -1;
                      if (!aPending && bPending) return 1;
                      return b.transactionDate.compareTo(a.transactionDate);
                    });
                  final recentTx = sorted.take(5).toList();
  
                  return Column(
                    children: recentTx.map((tx) {
                      final isIncome = tx.type == 'income';
                      final isTransfer = tx.sourceType == 'transfer';
                      final sign = isIncome ? '+' : (isTransfer ? '' : '-');
  
                      // Tra cứu động (Direction A)
                      final wallets = walletState.value ?? [];
                      final categories = ref.watch(categoriesNotifierProvider).value ?? [];
  
                      final localWallet = wallets.where((w) => w.id == tx.walletId).firstOrNull;
                      final localCategory = categories.where((c) => c.id == tx.categoryId).firstOrNull;
  
                      final walletName = localWallet?.name ?? tx.walletName ?? 'Ví';
                      final categoryIconStr = localCategory?.icon ?? tx.categoryIcon;
                      final categoryColorStr = localCategory?.color ?? tx.categoryColor;
  
                      final categoryIcon = CategoryUIConstants.getIconData(categoryIconStr);
                      final categoryColor = CategoryUIConstants.getColorFromHex(categoryColorStr);
  
                      final txCurrency = (localWallet != null && 
                          localWallet.currencyCode != null && 
                          localWallet.currencyCode.toString().isNotEmpty)
                      ? localWallet.currencyCode.toString()
                      : (tx.currencyCode ?? 'VND');
  
                      return _buildRecentTransaction(
                        ref: ref,
                        colors: colors,
                        title: tx.title,
                        sub: '$walletName • ${_formatDateTime(tx.transactionDate, tx.timezone, ref)}',
                        amount: '$sign${AppConstant.formatMoney(tx.amount, tx.currencyCode)} $txCurrency',
                        isIncome: isIncome,
                        icon: categoryIcon,
                        iconColor: categoryColor,
                        isPending: tx.status == 'pending',
                      );
                    }).toList(),
                  );
                },
                loading: () => const TransactionListShimmer(
                  itemCount: 5,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'Không thể tải giao dịch.',
                      style: TextStyle(color: colors.expenseRed),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
  
              // 🎯 4. GỢI Ý TIẾT KIỆM BANNER (GLASS BG)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'saving_tip'.tr(ref),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'saving_tip_desc'.tr(ref),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Chừa khoảng trống cho Bottom Bar trượt
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final colors = context.colors;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransaction({
    required WidgetRef ref,
    required AppColorsExtension colors,
    required String title,
    required String sub,
    required String amount,
    required bool isIncome,
    required IconData icon,
    required Color iconColor,
    bool isPending = false,
  }) {
    final displayColor = isIncome ? colors.incomeGreen : colors.expenseRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(isPending ? 0.85 : 1.0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPending
                ? Colors.orange.withOpacity(0.4)
                : colors.textSecondary.withOpacity(0.04),
            width: isPending ? 1.2 : 1.0,
          ),
          boxShadow: isPending ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'transaction_status_pending'.tr(ref),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: displayColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e-wallet':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.credit_card_rounded;
    }
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
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
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

  String _formatDateTime(DateTime date, String? txTimezone, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final tzName = txTimezone ?? user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;
      final offsetStr = offset.inMinutes == 0
          ? 'UTC'
          : 'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}';
      return '${DateFormat('dd/MM/yyyy HH:mm').format(tzDateTime)} ($offsetStr)';
    } catch (_) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}