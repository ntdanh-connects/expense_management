import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/core/language/app_language.dart';

final showBalanceProvider = StateProvider<bool>((ref) => true);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletState = ref.watch(walletNotifierProvider);
    final showBalance = ref.watch(showBalanceProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(
        hintText: 'search_hint'.tr(ref),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                  walletState.when(
                    data: (walletList) {
                      final showBalance = ref.watch(showBalanceProvider);
                      // Chỉ tính số dư từ các ví KHÔNG bị ẩn
                      final visibleWallets = walletList.where((w) => !w.isHidden).toList();
                      final totalBalance = visibleWallets.fold<double>(0, (sum, w) => sum + w.balance);
                      
                      String formatMoney(double value) {
                        RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                        String Function(Match) mathFunc = (Match match) => '${match[1]}.';
                        return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
                      }
                      
                      return Text(
                        showBalance ? '${formatMoney(totalBalance)} đ' : '•••••• đ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                    loading: () => const Text(
                      '... đ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    error: (_, __) => const Text(
                      '0 đ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
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
                                  const Text(
                                    '+12.4M',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                                  const Text(
                                    '-5.8M',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

                      String formatMoney(double value) {
                        RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                        String Function(Match) mathFunc = (Match match) => '${match[1]}.';
                        return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
                      }

                      final showBalance = ref.watch(showBalanceProvider);

                      return _buildWalletCard(
                        context: context,
                        title: wallet.name,
                        amount: showBalance ? '${formatMoney(wallet.balance)} đ' : '•••••• đ',
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
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.tune_rounded, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // DANH SÁCH GIAO DỊCH GẦN ĐÂY
            Text(
              'today_format'.tr(ref),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentTransaction(
              colors: colors,
              title: 'lunch_pho_thin'.tr(ref),
              sub: 'lunch_sub'.tr(ref),
              amount: '-65.000đ',
              isIncome: false,
              icon: Icons.restaurant_rounded,
              iconColor: Colors.orange,
            ),
            _buildRecentTransaction(
              colors: colors,
              title: 'uniqlo_vincom'.tr(ref),
              sub: 'uniqlo_sub'.tr(ref),
              amount: '-1.200.000đ',
              isIncome: false,
              icon: Icons.shopping_bag_rounded,
              iconColor: Colors.blue,
            ),
            _buildRecentTransaction(
              colors: colors,
              title: 'salary_may'.tr(ref),
              sub: 'salary_sub'.tr(ref),
              amount: '+35.000.000đ',
              isIncome: true,
              icon: Icons.payments_rounded,
              iconColor: Colors.green,
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
    required AppColorsExtension colors,
    required String title,
    required String sub,
    required String amount,
    required bool isIncome,
    required IconData icon,
    required Color iconColor,
  }) {
    final displayColor = isIncome ? colors.incomeGreen : colors.expenseRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
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
}