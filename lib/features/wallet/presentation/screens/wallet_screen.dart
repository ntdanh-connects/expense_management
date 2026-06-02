import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_card_item.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_screen_shimmer.dart';
import 'package:expense_management/features/wallet/presentation/provider/internal_transfer_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';

final showHiddenWalletsProvider = StateProvider<bool>((ref) => false);

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  WalletEntity? _fromWallet;
  WalletEntity? _toWallet;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🔄 Tự động đồng bộ hóa ngầm danh sách ví từ Backend ngay khi người dùng vào màn hình này
    Future.microtask(() {
      ref.read(walletNotifierProvider.notifier).refreshWallets();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletState = ref.watch(walletNotifierProvider);
    final transfers = ref.watch(internalTransferHistoryProvider);

    // Màn nền tím/xanh đen bóng đêm mượt mà, hoặc xám nhạt nhẹ nhàng
    final panelBg = isDark ? colors.surface.withOpacity(0.5) : const Color(0xFFF2F4FC);

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
              ref.read(showHiddenWalletsProvider.notifier).update((state) => !state);
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
            onRefresh: () => ref.read(walletNotifierProvider.notifier).refreshWallets(),
            color: colors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 16),

                // 💳 1. DANH SÁCH VÍ HÀNG NGANG (CAROUSEL) + CARD THÊM VÍ Ở CUỐI
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayedWallets.length + 1,
                    itemBuilder: (context, index) {
                      if (index < displayedWallets.length) {
                        final wallet = displayedWallets[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: WalletCardItem(
                            wallet: wallet,
                            onTap: () => context.push('/add-wallet', extra: wallet),
                          ),
                        );
                      } else {
                        // Card Thêm Ví Mới ở cuối danh sách
                        return _buildAddWalletCard(context, colors);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // 🔁 2. CHUYỂN KHOẢN NỘI BỘ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.primary.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề + Icon
                        Row(
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              color: colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'internal_transfer'.tr(ref),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Cụm Trích Từ -> Đến Ví
                        Row(
                          children: [
                            // Trích Từ
                            Expanded(
                              child: _buildWalletDropdown(
                                label: 'transfer_from'.tr(ref),
                                value: _fromWallet,
                                items: displayedWallets,
                                onChanged: (val) {
                                  setState(() {
                                    _fromWallet = val;
                                  });
                                },
                                colors: colors,
                              ),
                            ),
                            
                            // Nút arrow ở giữa
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),

                            // Đến Ví
                            Expanded(
                              child: _buildWalletDropdown(
                                label: 'transfer_to'.tr(ref),
                                value: _toWallet,
                                items: displayedWallets,
                                onChanged: (val) {
                                  setState(() {
                                    _toWallet = val;
                                  });
                                },
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Ô nhập số tiền
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colors.textSecondary.withOpacity(0.12),
                            ),
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'enter_amount_hint'.tr(ref),
                              hintStyle: TextStyle(
                                color: colors.textSecondary.withOpacity(0.6),
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                              suffixIcon: Container(
                                alignment: Alignment.centerRight,
                                width: 20,
                                child: Text(
                                  'đ',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nút chuyển tiền
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _executeTransfer(colors),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'transfer_now'.tr(ref),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 🧾 3. LỊCH SỬ CHUYỂN KHOẢN NỘI BỘ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'internal_transfer_history'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'details'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // List lịch sử giao dịch
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final tx = transfers[index];
                    return _buildTransferHistoryItem(tx, colors);
                  },
                ),
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

  // Widget Dropdown chọn ví
  Widget _buildWalletDropdown({
    required String label,
    required WalletEntity? value,
    required List<WalletEntity> items,
    required ValueChanged<WalletEntity?> onChanged,
    required AppColorsExtension colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.textSecondary.withOpacity(0.12),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<WalletEntity>(
              isExpanded: true,
              value: value,
              hint: Text(
                'select_wallet'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
                size: 18,
              ),
              items: items.map((w) {
                return DropdownMenuItem<WalletEntity>(
                  value: w,
                  child: Row(
                    children: [
                      Icon(
                        _getWalletIcon(w.type),
                        size: 14,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          w.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Card Thêm Ví Mới
  Widget _buildAddWalletCard(BuildContext context, AppColorsExtension colors) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: colors.primary.withOpacity(0.4),
        borderRadius: 24,
      ),
      child: GestureDetector(
        onTap: () => context.push('/add-wallet'),
        child: Container(
          width: 320,
          height: 180,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary,
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'add_new_wallet'.tr(ref),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dòng giao dịch lịch sử
  Widget _buildTransferHistoryItem(InternalTransferRecord tx, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.textSecondary.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.fromWalletName} ➔ ${tx.toWalletName}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(tx.date),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${_formatMoney(tx.amount)}đ',
            style: TextStyle(
              color: colors.expenseRed,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Thực hiện giao dịch chuyển khoản thông qua Provider nghiệp vụ
  void _executeTransfer(AppColorsExtension colors) {
    final amountStr = _amountController.text.trim();
    
    // Gọi thực thi logic ở Provider
    final errorKey = ref.read(internalTransferHistoryProvider.notifier).executeTransfer(
      fromWallet: _fromWallet,
      toWallet: _toWallet,
      amountStr: amountStr,
    );

    if (errorKey != null) {
      String errorMsg = '';
      if (errorKey == 'select_source_dest_wallet_error') {
        errorMsg = 'select_source_dest_wallet_error'.tr(ref);
      } else if (errorKey == 'same_wallet_error') {
        errorMsg = 'same_wallet_error'.tr(ref);
      } else if (errorKey == 'enter_amount_error') {
        errorMsg = 'enter_amount_error'.tr(ref);
      } else if (errorKey == 'invalid_amount_error') {
        errorMsg = 'invalid_amount_error'.tr(ref);
      } else if (errorKey == 'insufficient_balance_error') {
        errorMsg = '${'insufficient_balance_error'.tr(ref)} "${_fromWallet?.name}"!';
      } else {
        errorMsg = errorKey;
      }
      _showSnackBar(errorMsg, isError: true);
    } else {
      _amountController.clear();
      setState(() {
        _fromWallet = null;
        _toWallet = null;
      });
      _showSnackBar('transfer_success'.tr(ref), isError: false);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? colors.expenseRed : colors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  String _formatMoney(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';
    return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
  }

  String _formatDate(DateTime date) {
    final isEn = ref.read(translationsProvider)['add_new_wallet'] == 'Add new wallet';
    if (isEn) {
      final listMonths = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${listMonths[date.month - 1]} ${date.day}, ${date.year}';
    } else {
      return '${date.day} tháng ${date.month}, ${date.year}';
    }
  }
}

// Painter vẽ viền đứt nét (Dashed Border) sang xịn mịn chuẩn mockup
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    var distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final length = dashWidth;
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.borderRadius != borderRadius;
}