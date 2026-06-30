import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/di/domain_providers.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/swipe_to_confirm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';

import '../widgets/sandbox_simulate_transfer/sandbox_banner.dart';
import '../widgets/sandbox_simulate_transfer/sandbox_wallet_selector.dart';
import '../widgets/sandbox_simulate_transfer/sandbox_amount_input.dart';

class SandboxSimulateTransferScreen extends ConsumerStatefulWidget {
  const SandboxSimulateTransferScreen({super.key});

  @override
  ConsumerState<SandboxSimulateTransferScreen> createState() =>
      _SandboxSimulateTransferScreenState();
}

class _SandboxSimulateTransferScreenState
    extends ConsumerState<SandboxSimulateTransferScreen> {
  final _amountController = TextEditingController(text: '500.000');
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

    final cleanAmount = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
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
      final transactionId = await ref
          .read(simulateSandboxTransferUseCaseProvider)
          .execute(
            walletId: _selectedWallet!.id,
            amount: amount,
            senderName: senderName,
            notes: notes.isNotEmpty ? notes : null,
          );

      final pref = ref.read(notificationPreferencesProvider).value;
      final showPush = pref?.pushEnabled ?? true;

      if (showPush) {
        final notifId = DateTime.now().millisecondsSinceEpoch.hashCode;
        final formattedAmount = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        ).format(amount);
        final title = 'Biến động số dư';
        final body =
            'Ví "${_selectedWallet!.name}" nhận +$formattedAmount từ $senderName.';

        await LocalNotificationService.showNotification(
          id: notifId,
          title: title,
          body: body,
          payload: transactionId,
        );

        final userId = ref.read(currentUserProvider)?.id ?? '';
        if (userId.isNotEmpty) {
          final localNotif = await LocalNotificationStorage.createAndSave(
            userId: userId,
            type: 'p2p_transfer',
            title: title,
            body: body,
            metadata: {
              'transaction_id': transactionId,
              'amount': amount,
              'sender_name': senderName,
              'notes': notes,
            },
          );
          if (localNotif != null) {
            ref
                .read(notificationNotifierProvider.notifier)
                .addLocalNotification(localNotif);
          }
        }
      }

      ref.invalidate(transactionListProvider);
      ref.invalidate(walletNotifierProvider);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      _showSnackBar('Giả lập nạp tiền Sandbox thành công!', isError: false);
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
    final localeCode = ref.watch(localeProvider);
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: walletsAsync.when(
        data: (wallets) {
          final filteredWallets = wallets
              .where((w) => w.type != 'cash' && w.currencyCode == 'VND')
              .toList();

          if (filteredWallets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy ví hợp lệ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Quay lại',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectedWallet == null ||
              !filteredWallets.any((w) => w.id == _selectedWallet!.id)) {
            _selectedWallet = filteredWallets.first;
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    const SandboxBanner(),
                    const SizedBox(height: 24),

                    // 💳 CHỌN VÍ NHẬN TIỀN
                    SandboxWalletSelector(
                      selectedWallet: _selectedWallet,
                      wallets: filteredWallets,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedWallet = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 💵 NHẬP SỐ TIỀN
                    SandboxAmountInput(
                      amountController: _amountController,
                      localeCode: localeCode,
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.04)
                            : const Color(0xFFF3F4F6),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.04)
                            : const Color(0xFFF3F4F6),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
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
