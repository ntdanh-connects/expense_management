import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

final showBalanceProvider = StateProvider<bool>((ref) => true);

class DashboardBalanceCard extends ConsumerWidget {
  const DashboardBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final walletState = ref.watch(walletNotifierProvider);
    final showBalance = ref.watch(showBalanceProvider);

    final userCurrency =
        ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
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
      final rates =
          ratesData?.rates.map(
            (k, v) => MapEntry(k.toUpperCase(), v.toDouble()),
          ) ??
          fallbackRates;
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

    return Container(
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
          ),
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
                  ref
                      .read(showBalanceProvider.notifier)
                      .update((state) => !state);
                },
                child: Icon(
                  showBalance
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            monthlyIncomeStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            monthlyExpenseStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
