import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/widget/swipe_to_confirm_button.dart';
import 'package:elegant_notification/elegant_notification.dart';

class QrTransferConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> payeeData;

  const QrTransferConfirmScreen({super.key, required this.payeeData});

  @override
  ConsumerState<QrTransferConfirmScreen> createState() => _QrTransferConfirmScreenState();
}

class _QrTransferConfirmScreenState extends ConsumerState<QrTransferConfirmScreen> {
  WalletEntity? _selectedWallet;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Parse payeeData amount & description if pre-filled
    if (widget.payeeData['amount'] != null) {
      final double amt = double.tryParse(widget.payeeData['amount'].toString()) ?? 0.0;
      if (amt > 0) {
        _amountController.text = NumberFormat('#,###').format(amt);
      }
    }
    if (widget.payeeData['description'] != null) {
      _descController.text = widget.payeeData['description'].toString();
    }

    // Set default wallet
    Future.microtask(() {
      final wallets = ref.read(walletNotifierProvider).value ?? [];
      if (wallets.isNotEmpty) {
        setState(() {
          _selectedWallet = wallets.firstWhere(
            (w) => w.type == 'bank',
            orElse: () => wallets.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    if (_selectedWallet == null) return;
    
    final cleanAmountString = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double? amount = double.tryParse(cleanAmountString);
    
    if (amount == null || amount <= 0) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Vui lòng nhập số tiền chuyển hợp lệ!'),
      ).show(context);
      return;
    }

    if (amount > _selectedWallet!.balance) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: Text('insufficient_balance_error'.tr(ref)),
      ).show(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    AppLogger.info("💸 [QR-Transfer] Gửi yêu cầu chuyển tiền từ ví ${_selectedWallet!.name} đến ${widget.payeeData['payee_name']} số tiền $amount");

    final success = await ref.read(qrTransferProvider.notifier).executeTransfer(
      fromWalletId: _selectedWallet!.id,
      payeeType: widget.payeeData['type'] ?? 'internal',
      amount: amount,
      notes: _descController.text.isNotEmpty ? _descController.text : 'QR transfer',
      payeeUserId: widget.payeeData['payee_user_id'],
      bankCode: widget.payeeData['bank_code'],
      accountNumber: widget.payeeData['account_number'] ?? widget.payeeData['identifier'],
      payeeName: widget.payeeData['payee_name'],
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      AppLogger.info("✅ [QR-Transfer] Chuyển tiền thành công! Đồng bộ ví...");
      
      // Sync local SQLite DB with updated remote balances
      await ref.read(walletNotifierProvider.notifier).refreshWallets();
      
      if (mounted) {
        ElegantNotification.success(
          title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('transfer_success_msg'.tr(ref)),
        ).show(context);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      }
    } else if (mounted) {
      AppLogger.error("🚨 [QR-Transfer] Chuyển tiền thất bại!");
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: Text('transfer_failed_msg'.tr(ref)),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = ref.watch(walletNotifierProvider).value ?? [];

    final payeeName = widget.payeeData['payee_name'] ?? 'Người nhận';
    final isInternal = widget.payeeData['type'] == 'internal';
    final identifier = widget.payeeData['identifier'] ?? widget.payeeData['account_number'] ?? '';
    final bankName = widget.payeeData['bank_name'] ?? '';
    final bankLogo = widget.payeeData['bank_logo'];

    return Scaffold(
      backgroundColor: color.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xác nhận chuyển khoản',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SENDER CARD
                Text(
                  'sender_info'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.textSecondary.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<WalletEntity>(
                          value: _selectedWallet,
                          dropdownColor: color.surface,
                          items: wallets.map((w) {
                            return DropdownMenuItem<WalletEntity>(
                              value: w,
                              child: Row(
                                children: [
                                  Icon(
                                    w.type == 'bank' ? Icons.account_balance_rounded : Icons.account_balance_wallet_rounded,
                                    color: color.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    w.name,
                                    style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedWallet = val;
                            });
                          },
                        ),
                      ),
                      if (_selectedWallet != null) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'available_balance'.tr(ref),
                              style: TextStyle(color: color.textSecondary, fontSize: 13),
                            ),
                            Text(
                              "${NumberFormat('#,###').format(_selectedWallet!.balance)}đ",
                              style: TextStyle(color: color.incomeGreen, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 20,
                      child: Icon(Icons.arrow_downward_rounded, color: Colors.white),
                    ),
                  ),
                ),

                // 2. RECIPIENT CARD
                Text(
                  'recipient_info'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.textSecondary.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isInternal)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: widget.payeeData['avatar_url'] != null ? NetworkImage(widget.payeeData['avatar_url']) : null,
                          child: widget.payeeData['avatar_url'] == null ? const Icon(Icons.person) : null,
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: bankLogo != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(bankLogo, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.account_balance_rounded, color: Colors.blue),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payeeName,
                              style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isInternal ? "ID: $identifier" : "$bankName - $identifier",
                              style: TextStyle(color: color.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. INPUT AMOUNT
                Text(
                  'amount'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: color.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'đ',
                    suffixStyle: TextStyle(color: color.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: color.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
                const SizedBox(height: 16),

                // 4. DESCRIPTION
                Text(
                  'notes'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  style: TextStyle(color: color.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nhập lời nhắn chuyển tiền...',
                    filled: true,
                    fillColor: color.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),

                // 5. SLIDE TO CONFIRM BUTTON
                SwipeToConfirmButton(
                  onConfirmed: _executeTransfer,
                  text: 'slide_to_confirm_transfer'.tr(ref),
                  activeColor: color.primary,
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
