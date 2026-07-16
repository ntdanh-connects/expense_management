import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/analytic/presentation/screens/statistics_tab.dart';
import 'package:expense_management/features/analytic/presentation/screens/balance_fluctuation_tab.dart';
import 'package:expense_management/features/analytic/presentation/screens/budget_tab.dart';
import 'package:expense_management/features/analytic/presentation/screens/habit_analysis_tab.dart';

class AnalyticScreen extends ConsumerStatefulWidget {
  const AnalyticScreen({super.key});

  @override
  ConsumerState<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends ConsumerState<AnalyticScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final state = GoRouterState.of(context);
      final tab = state.uri.queryParameters['tab'];
      if (tab != null &&
          (tab == 'statistics' ||
              tab == 'balance_fluctuations' ||
              tab == 'budget' ||
              tab == 'habit_analysis')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedAnalyticTabProvider.notifier).state = tab;
          }
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedSubTab = ref.watch(selectedAnalyticTabProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(hintText: 'search_hint'.tr(ref)),
      floatingActionButton: () {
        if (selectedSubTab != 'budget') return null;

        final month = ref.watch(selectedBudgetMonthProvider);
        final year = ref.watch(selectedBudgetYearProvider);
        final now = DateTime.now();
        final isPastMonth =
            year < now.year || (year == now.year && month < now.month);

        if (isPastMonth) return null;

        return FloatingActionButton(
          backgroundColor: colors.primary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            context.push(RoutePaths.budgetCreate).then((_) {
              ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
            });
          },
        );
      }(),
      body: RefreshIndicator(
        onRefresh: () async {
          // 1. Refresh transactions (silent)
          await ref
              .read(transactionListProvider.notifier)
              .refreshTransactions(silent: true);
          await ref
              .read(filteredTransactionListProvider.notifier)
              .refreshTransactions(silent: true);

          // 2. Refresh wallets
          await ref.read(walletNotifierProvider.notifier).refreshWallets();

          // 3. Refresh budgets (silent)
          await ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);

          // 4. Refresh categories (silent)
          await ref
              .read(categoriesNotifierProvider.notifier)
              .refreshCategories(silent: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 1. BỘ PHÂN LOẠI NGANG PHỤ (THỐNG KÊ / BIẾN ĐỘNG SỐ DƯ / NGÂN SÁCH / THÓI QUEN)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSubTabButton('statistics', selectedSubTab),
                    const SizedBox(width: 8),
                    _buildSubTabButton('balance_fluctuations', selectedSubTab),
                    const SizedBox(width: 8),
                    _buildSubTabButton('budget', selectedSubTab),
                    const SizedBox(width: 8),
                    _buildSubTabButton('habit_analysis', selectedSubTab),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 🟢 Conditional Rendering depending on active SubTab
              if (selectedSubTab == 'statistics') ...[
                const StatisticsTab(),
              ] else if (selectedSubTab == 'balance_fluctuations') ...[
                const BalanceFluctuationTab(),
              ] else if (selectedSubTab == 'budget') ...[
                const BudgetTab(),
              ] else if (selectedSubTab == 'habit_analysis') ...[
                const HabitAnalysisTab(),
              ],
              const SizedBox(
                height: 80,
              ), // Dành khoảng trống cho Bottom Bar trượt
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String key, String selectedSubTab) {
    final colors = context.colors;
    final isSelected = selectedSubTab == key;

    return GestureDetector(
      onTap: () {
        ref.read(selectedAnalyticTabProvider.notifier).state = key;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.textSecondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          key.tr(ref),
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
