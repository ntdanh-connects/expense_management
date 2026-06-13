import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
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

    // Set default wallet from filtered list
    Future.microtask(() {
      final wallets = ref.read(walletNotifierProvider).value ?? [];
      final isInternal = widget.payeeData['type'] == 'internal';
      
      final filtered = wallets.where((w) {
        if (w.type == 'cash') return false;
        if (!isInternal && w.currencyCode != 'VND') return false;
        return true;
      }).toList();

      if (filtered.isNotEmpty) {
        setState(() {
          _selectedWallet = filtered.firstWhere(
            (w) => w.type == 'bank',
            orElse: () => filtered.first,
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
    final wallets = ref.read(walletNotifierProvider).value ?? [];
    final isInternal = widget.payeeData['type'] == 'internal';
    final filtered = wallets.where((w) {
      if (w.type == 'cash') return false;
      if (!isInternal && w.currencyCode != 'VND') return false;
      return true;
    }).toList();

    if (_selectedWallet == null || !filtered.any((w) => w.id == _selectedWallet!.id)) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Vui lòng chọn ví hợp lệ để thực hiện chuyển khoản!'),
      ).show(context);
      return;
    }
    
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

    final rawPayeeName = widget.payeeData['payee_name']?.toString().trim() ?? '';
    final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
        ? 'Không xác định'
        : rawPayeeName;

    AppLogger.info("💸 [QR-Transfer] Gửi yêu cầu chuyển tiền từ ví ${_selectedWallet!.name} đến $payeeName số tiền $amount");

    final result = await ref.read(qrTransferProvider.notifier).executeTransfer(
      fromWalletId: _selectedWallet!.id,
      payeeType: widget.payeeData['type'] ?? 'internal',
      amount: amount,
      notes: _descController.text.isNotEmpty ? _descController.text : 'QR transfer',
      payeeUserId: widget.payeeData['payee_user_id'],
      bankCode: widget.payeeData['bank_code'],
      accountNumber: widget.payeeData['account_number'] ?? widget.payeeData['identifier'],
      payeeName: payeeName,
    );

    setState(() {
      _isLoading = false;
    });

    final isSuccess = result != null && result['status'] == 'success';

    if (isSuccess && mounted) {
      AppLogger.info("✅ [QR-Transfer] Chuyển tiền thành công! Đồng bộ ví...");
      
      // Sync local SQLite DB with updated remote balances
      await ref.read(walletNotifierProvider.notifier).refreshWallets();
      // Refresh transactions history to include the new transfer with payee info
      await ref.read(transactionListProvider.notifier).refreshTransactions(silent: true);
      
      final identifier = widget.payeeData['identifier'] ?? widget.payeeData['account_number'] ?? '';
      final bankName = widget.payeeData['bank_name'] ?? '';

      if (mounted) {
        context.push('/qr-transfer-result', extra: {
          'result': result,
          'sender_wallet': _selectedWallet?.name ?? '',
          'notes': _descController.text.isNotEmpty ? _descController.text : 'QR transfer',
          'bank_name': bankName,
          'identifier': identifier,
          'type': widget.payeeData['type'] ?? 'internal',
        });
      }
    } else if (mounted) {
      AppLogger.error("🚨 [QR-Transfer] Chuyển tiền thất bại!");
      final errMsg = (result != null && result['message'] != null)
          ? result['message'].toString()
          : 'transfer_failed_msg'.tr(ref);
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: Text(errMsg),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = ref.watch(walletNotifierProvider).value ?? [];
    final isInternal = widget.payeeData['type'] == 'internal';
    
    final filteredWallets = wallets.where((w) {
      if (w.type == 'cash') return false;
      if (!isInternal && w.currencyCode != 'VND') return false;
      return true;
    }).toList();

    final rawPayeeName = widget.payeeData['payee_name']?.toString().trim() ?? '';
    final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
        ? 'Không xác định'
        : rawPayeeName;
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
                      if (filteredWallets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            isInternal
                                ? 'qr_transfer_internal_no_wallet_warning'.tr(ref)
                                : 'qr_transfer_external_no_wallet_warning'.tr(ref),
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        )
                      else
                        DropdownButtonHideUnderline(
                          child: DropdownButton<WalletEntity>(
                            value: filteredWallets.contains(_selectedWallet) ? _selectedWallet : filteredWallets.first,
                            dropdownColor: color.surface,
                            items: filteredWallets.map((w) {
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
                                      "${w.name} (${w.currencyCode})",
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
