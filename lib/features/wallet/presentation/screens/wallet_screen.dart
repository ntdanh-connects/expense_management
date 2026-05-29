import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_card_item.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_screen_shimmer.dart';
import 'package:expense_management/features/wallet/presentation/provider/internal_transfer_provider.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ví của tôi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: walletState.when(
        data: (walletList) {
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
                    itemCount: walletList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < walletList.length) {
                        final wallet = walletList[index];
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
                              'Chuyển khoản nội bộ',
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
                                label: 'TRÍCH TỪ',
                                value: _fromWallet,
                                items: walletList,
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
                                label: 'ĐẾN VÍ',
                                value: _toWallet,
                                items: walletList,
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
                              hintText: 'Nhập số tiền...',
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
                            child: const Text(
                              'Chuyển ngay',
                              style: TextStyle(
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
                        'Lịch sử chuyển khoản nội bộ',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Chi tiết',
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
            'Lỗi hệ thống: $err',
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
                'Chọn ví',
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
                'Thêm ví mới',
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

  // Thực hiện giao dịch chuyển khoản
  void _executeTransfer(AppColorsExtension colors) async {
    if (_fromWallet == null || _toWallet == null) {
      _showSnackBar('Vui lòng chọn đầy đủ Ví nguồn và Ví đích!', isError: true);
      return;
    }
    if (_fromWallet!.id == _toWallet!.id) {
      _showSnackBar('Ví nguồn và Ví đích không được trùng nhau!', isError: true);
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      _showSnackBar('Vui lòng nhập số tiền cần chuyển!', isError: true);
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _showSnackBar('Số tiền chuyển không hợp lệ!', isError: true);
      return;
    }

    if (_fromWallet!.balance < amount) {
      _showSnackBar('Số dư ví "${_fromWallet!.name}" không đủ!', isError: true);
      return;
    }

    try {
      // Thêm record vào lịch sử chuyển tiền (chỉ lưu local tạm thời)
      ref.read(internalTransferHistoryProvider.notifier).addTransfer(
            fromWalletName: _fromWallet!.name,
            toWalletName: _toWallet!.name,
            amount: amount,
          );

      _amountController.clear();
      setState(() {
        _fromWallet = null;
        _toWallet = null;
      });

      _showSnackBar('Chuyển khoản nội bộ thành công!', isError: false);
    } catch (e) {
      _showSnackBar('Chuyển tiền thất bại: $e', isError: true);
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
    final listThang = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12'
    ];
    return '${date.day} ${listThang[date.month - 1]}, ${date.year}';
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