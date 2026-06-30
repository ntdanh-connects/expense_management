import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet/wallet_carousel_section.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet/wallet_internal_transfer_section.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet/wallet_external_transfer_section.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet/wallet_transfer_history_section.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet/wallet_screen_shimmer.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletState = ref.watch(walletNotifierProvider);

    final panelBg = isDark
        ? colors.surface.withOpacity(0.5)
        : const Color(0xFFF2F4FC);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'my_wallets'.tr(ref),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(showHiddenWalletsProvider)
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white,
            ),
            tooltip: ref.watch(showHiddenWalletsProvider)
                ? 'hide_hidden_wallets'.tr(ref)
                : 'show_hidden_wallets'.tr(ref),
            onPressed: () {
              ref
                  .read(showHiddenWalletsProvider.notifier)
                  .update((state) => !state);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: walletState.when(
        data: (walletList) {
          final showHidden = ref.watch(showHiddenWalletsProvider);
          final displayedWallets = showHidden
              ? walletList
              : walletList.where((w) => !w.isHidden).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(walletNotifierProvider.notifier).refreshWallets(),
            color: colors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 💳 1. DANH SÁCH VÍ HÀNG NGANG (CAROUSEL) + CARD THÊM VÍ Ở CUỐI
                  WalletCarouselSection(displayedWallets: displayedWallets),
                  const SizedBox(height: 32),

                  // 🔁 2. CHUYỂN TIỀN NỘI BỘ (COLLAPSIBLE)
                  WalletInternalTransferSection(
                    displayedWallets: displayedWallets,
                    panelBg: panelBg,
                  ),
                  const SizedBox(height: 20),

                  // 🔁 3. CHUYỂN TIỀN ĐẾN NGƯỜI KHÁC (COLLAPSIBLE)
                  WalletExternalTransferSection(
                    displayedWallets: displayedWallets,
                    panelBg: panelBg,
                  ),
                  const SizedBox(height: 32),

                  // 🧾 4. LỊCH SỬ CHUYỂN KHOẢN NỘI BỘ
                  const WalletTransferHistorySection(),
                ],
              ),
            ),
          );
        },
        loading: () => const WalletShimmerLoading(),
        error: (err, _) => Center(
          child: Text(
            '${'error_occurred'.tr(ref)}: $err',
            style: TextStyle(color: colors.expenseRed),
          ),
        ),
      ),
    );
  }
}
