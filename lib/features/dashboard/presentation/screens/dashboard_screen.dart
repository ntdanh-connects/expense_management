import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_ai_digest_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/walkthrough_dialog.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_balance_card.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_wallet_card.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_quick_actions.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_recent_transaction.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/dashboard/dashboard_saving_tip.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWalkthrough();
    });
  }

  void _checkAndShowWalkthrough() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final storage = ref.read(localStoreHelperProvider);
      if (storage.needsNewUserSetup(user.id) &&
          !storage.hasSeenWalkthrough(user.id)) {
        storage.setSeenWalkthrough(user.id, true);
        storage.setNeedsNewUserSetup(user.id, false);
        _showWalkthroughDialog(context, ref, user.id);
      }
    }
  }

  void _showWalkthroughDialog(BuildContext context, WidgetRef ref, String userId) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Walkthrough',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurveTween(curve: Curves.easeOutBack).animate(anim1);
        return Transform.scale(
          scale: curve.value,
          child: FadeTransition(
            opacity: anim1,
            child: Align(
              alignment: Alignment.center,
              child: WalkthroughDialogContent(colors: colors, isDark: isDark),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWalkthrough();
    });

    final ref = this.ref;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(hintText: 'search_hint'.tr(ref)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
              .read(categoriesNotifierProvider.notifier)
              .refreshCategories(silent: true);
          ref.invalidate(fetchDashboardSummaryProvider);
          try {
            await ref.read(fetchDashboardSummaryProvider.future);
          } catch (_) {}
          ref.invalidate(transactionListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💳 1. TỔNG SỐ DƯ CARD
              const DashboardBalanceCard(),
              const SizedBox(height: 24,),
              const DashboardAiDigestCard(),
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

              // DANH SÁCH VÍ HÀNG NGANG
              const DashboardWalletList(),
              const SizedBox(height: 20),

              // THANH PHÍM TẮT MOMO-STYLE
              Text(
                'Features'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const DashboardQuickActions(),
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
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colors.primary,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // DANH SÁCH GIAO DỊCH GẦN ĐÂY
              const DashboardRecentTransactions(),
              const SizedBox(height: 20),

              // 🎯 4. GỢI Ý TIẾT KIỆM BANNER
              const DashboardSavingTip(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
