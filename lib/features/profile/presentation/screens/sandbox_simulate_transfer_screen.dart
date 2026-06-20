import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/swipe_to_confirm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SandboxSimulateTransferScreen extends ConsumerStatefulWidget {
  const SandboxSimulateTransferScreen({super.key});

  @override
  ConsumerState<SandboxSimulateTransferScreen> createState() => _SandboxSimulateTransferScreenState();
}

class _SandboxSimulateTransferScreenState extends ConsumerState<SandboxSimulateTransferScreen> {
  final _amountController = TextEditingController(text: '500,000');
  final _senderNameController = TextEditingController(text: 'NGUYEN VAN B');
  final _notesController = TextEditingController(text: 'Chuyển tiền ăn trưa');

  WalletEntity? _selectedWallet;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _senderNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _executeSimulation(AppColorsExtension colors) async {
    if (_selectedWallet == null) {
      _showSnackBar('Vui lòng chọn ví nhận tiền!', isError: true);
      return;
    }

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanAmount);
    if (amount == null || amount <= 0) {
      _showSnackBar('Số tiền chuyển không hợp lệ!', isError: true);
      return;
    }

    final senderName = _senderNameController.text.trim();
    if (senderName.isEmpty) {
      _showSnackBar('Vui lòng nhập tên người gửi!', isError: true);
      return;
    }

    final notes = _notesController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(simulateSandboxTransferUseCaseProvider).execute(
            walletId: _selectedWallet!.id,
            amount: amount,
            senderName: senderName,
            notes: notes.isNotEmpty ? notes : null,
          );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      
      // Thành công thì thông báo
      _showSnackBar('Giả lập nạp tiền Sandbox thành công!', isError: false);
      
      // Quay lại màn hình cũ
      context.pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      _showSnackBar('Giả lập thất bại: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? colors.expenseRed : colors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletNotifierProvider);

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
        title: const Text(
          'Sandbox Simulate',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: walletsAsync.when(
        data: (wallets) {
          // Lọc bỏ ví tiền mặt và ví ngoại tệ (chỉ giữ lại ví khác cash và dùng VND)
          final filteredWallets = wallets.where((w) => w.type != 'cash' && w.currencyCode == 'VND').toList();

          if (filteredWallets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: colors.textSecondary),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy ví hợp lệ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng tạo ví Ngân hàng hoặc Ví điện tử với đơn vị tiền tệ VND để tiếp tục giả lập.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Khởi tạo ví đầu tiên nếu chưa chọn hoặc ví cũ không còn nằm trong danh sách lọc
          if (_selectedWallet == null || !filteredWallets.any((w) => w.id == _selectedWallet!.id)) {
            _selectedWallet = filteredWallets.first;
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner thông tin giả lập
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: colors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tính năng này dùng để giả lập việc nhận tiền từ tài khoản VietinBank Sandbox của hệ thống.',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 💳 CHỌN VÍ NHẬN TIỀN
                    Text(
                      'Ví thụ hưởng'.toUpperCase(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<WalletEntity>(
                          value: _selectedWallet,
                          isExpanded: true,
                          dropdownColor: colors.surface,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          items: filteredWallets.map((wallet) {
                            return DropdownMenuItem<WalletEntity>(
                              value: wallet,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(wallet.color.replaceAll('#', 'FF'), radix: 16)),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${wallet.name} (${AppConstant.formatMoney(wallet.balance)} đ)'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedWallet = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 💵 NHẬP SỐ TIỀN
                    Text(
                      'Số tiền nhận (VND)'.toUpperCase(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nhập số tiền nạp...',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          if (val.isEmpty) return;
                          final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
                          final double? amt = double.tryParse(cleanString);
                          if (amt != null) {
                            final formatted = NumberFormat('#,###').format(amt);
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.fromPosition(TextPosition(offset: formatted.length)),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 👤 TÊN NGƯỜI GỬI
                    Text(
                      'Tên người gửi (Sandbox)'.toUpperCase(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _senderNameController,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tên người gửi...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 📝 NỘI DUNG CHUYỂN TIỀN
                    Text(
                      'Nội dung chuyển khoản'.toUpperCase(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _notesController,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nhập nội dung chuyển khoản...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Swipe hoặc Button xác nhận giả lập
                    SwipeToConfirmButton(
                      text: 'Vuốt để giả lập nhận tiền',
                      activeColor: colors.primary,
                      onConfirmed: () async {
                        HapticFeedback.vibrate();
                        await Future.delayed(const Duration(milliseconds: 200));
                        _executeSimulation(colors);
                      },
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                AbsorbPointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Lỗi tải ví: $err',
            style: TextStyle(color: colors.expenseRed),
          ),
        ),
      ),
    );
  }
}
