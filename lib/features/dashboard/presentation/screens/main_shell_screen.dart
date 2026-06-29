import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/shared/widgets/custom_sliding_bottom_bar.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/main_shell/floating_ai_button.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).syncUserProfileImplicit();
      ref
          .read(currentMonthBudgetsProvider.future)
          .catchError((_) => <BudgetDto>[]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(walletNotifierProvider.notifier).refreshWallets();
      ref
          .read(transactionListProvider.notifier)
          .refreshTransactions(silent: true);
      ref
          .read(filteredTransactionListProvider.notifier)
          .refreshTransactions(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: widget.navigationShell,
          bottomNavigationBar: CustomSlidingBottomBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) {
              if (index != 2) {
                ref.read(selectedAnalyticTabProvider.notifier).state =
                    'statistics';
              }
              if (index == 1) {
                ref
                    .read(filteredTransactionListProvider.notifier)
                    .refreshTransactions(silent: true);
              }
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
          ),
        ),
        const FloatingAiButton(),
      ],
    );
  }
}
