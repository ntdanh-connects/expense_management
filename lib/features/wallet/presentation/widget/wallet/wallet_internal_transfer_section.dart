import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/internal_transfer_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';

class WalletInternalTransferSection extends ConsumerStatefulWidget {
  final List<WalletEntity> displayedWallets;
  final Color panelBg;

  const WalletInternalTransferSection({
    super.key,
    required this.displayedWallets,
    required this.panelBg,
  });

  @override
  ConsumerState<WalletInternalTransferSection> createState() =>
      _WalletInternalTransferSectionState();
}

class _WalletInternalTransferSectionState
    extends ConsumerState<WalletInternalTransferSection> {
  WalletEntity? _fromWallet;
  WalletEntity? _toWallet;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isTransferring = false;
  bool _isInternalTransferExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
    _notesController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userCurrency = ref.watch(
      currentUserProvider.select((u) => u?.currency),
    );
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: widget.panelBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colors.primary.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clickable Header
            GestureDetector(
              onTap: () {
                setState(() {
                  _isInternalTransferExpanded = !_isInternalTransferExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Icon(
                    _isInternalTransferExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),

            if (_isInternalTransferExpanded) ...[
              const SizedBox(height: 24),
              // Cụm Trích Từ -> Đến Ví
              Row(
                children: [
                  // Trích Từ
                  Expanded(
                    child: _buildWalletDropdown(
                      label: 'transfer_from'.tr(ref),
                      value: _fromWallet,
                      items: _toWallet != null
                          ? widget.displayedWallets
                                .where(
                                  (w) =>
                                      w.currencyCode == _toWallet!.currencyCode,
                                )
                                .toList()
                          : widget.displayedWallets,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(
                              0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                      items: _fromWallet != null
                          ? widget.displayedWallets
                                .where(
                                  (w) =>
                                      w.currencyCode ==
                                      _fromWallet!.currencyCode,
                                )
                                .toList()
                          : widget.displayedWallets,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white,
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
                      color: colors.textSecondary.withOpacity(
                        0.6,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    suffixIcon: Container(
                      alignment: Alignment.centerRight,
                      width: 20,
                      child: Text(
                        _fromWallet != null
                            ? AppConstant.getCurrencySymbol(
                                _fromWallet!.currencyCode,
                              )
                            : currencySymbol,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isEmpty) return;
                    final cleanString = val.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    double? amt = double.tryParse(cleanString);
                    if (amt != null) {
                      if (amt > 500000000) {
                        amt = 500000000;
                      }
                      final formatted = _formatMoney(amt, 'VND');
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: formatted.length),
                        ),
                      );
                    }
                  },
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountController,
                builder: (context, value, child) {
                  final cleanString = value.text.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final double? amt = double.tryParse(
                    cleanString,
                  );
                  if (amt == null || amt == 0) {
                    return const SizedBox.shrink();
                  }
                  final wordRepresentation = formatNumberToWords(
                    amt,
                    localeCode,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 4.0,
                    ),
                    child: Text(
                      '($wordRepresentation)',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Ô nhập ghi chú chuyển khoản
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.textSecondary.withOpacity(0.12),
                  ),
                ),
                child: TextField(
                  controller: _notesController,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung chuyển khoản *',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  maxLength: 200,
                ),
              ),
              const SizedBox(height: 20),

              // Nút chuyển tiền
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isTransferring
                      ? null
                      : () => _executeTransfer(colors),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTransferring
                        ? colors.primary.withOpacity(0.5)
                        : colors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isTransferring
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDropdown({
    required String label,
    required WalletEntity? value,
    required List<WalletEntity> items,
    required ValueChanged<WalletEntity?> onChanged,
    required AppColorsExtension colors,
    double labelSize = 10,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: labelSize > 10 ? colors.textPrimary : colors.textSecondary,
              fontSize: labelSize,
              fontWeight: FontWeight.bold,
              letterSpacing: labelSize > 10 ? 0.0 : 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.textSecondary.withOpacity(0.12)),
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

  String _formatMoney(double value, [String? currencyCode]) {
    final String code = (currencyCode ?? 'VND').toUpperCase();
    final int decimals = (code == 'VND' || code == 'JPY') ? 0 : 2;

    if (decimals == 0) {
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String mathFunc(Match match) => '${match[1]}.';
      return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
    } else {
      final parts = value.toStringAsFixed(2).split('.');
      final String wholePart = parts[0];
      final String decimalPart = parts[1];

      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String mathFunc(Match match) => '${match[1]},';
      final String formattedWhole = wholePart.replaceAllMapped(reg, mathFunc);
      return '$formattedWhole.$decimalPart';
    }
  }

  void _executeTransfer(AppColorsExtension colors) async {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final notes = _notesController.text.trim();

    final amounVal = double.tryParse(amountStr) ?? 0.0;
    if(amounVal < 1000){
      _showSnackBar('Số tiền chuyển khoản tối thiểu là 1.000đ', isError: true);
      return;
    }

    if (notes.isEmpty) {
      _showSnackBar('Nội dung chuyển khoản bắt buộc phải nhập.', isError: true);
      return;
    }

    setState(() {
      _isTransferring = true;
    });

    try {
      final errorKey = await ref
          .read(internalTransferHistoryProvider.notifier)
          .executeTransfer(
            fromWallet: _fromWallet,
            toWallet: _toWallet,
            amountStr: amountStr,
            notes: notes,
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
          errorMsg =
              '${'insufficient_balance_error'.tr(ref)} "${_fromWallet?.name}"!';
        } else {
          errorMsg = errorKey;
        }
        _showSnackBar(errorMsg, isError: true);
      } else {
        final sourceWalletName = _fromWallet?.name;
        final targetWalletName = _toWallet?.name;
        final currencyCode = _fromWallet?.currencyCode ?? 'VND';

        _amountController.clear();
        _notesController.clear();
        setState(() {
          _fromWallet = null;
          _toWallet = null;
        });
        _showSnackBar('transfer_success'.tr(ref), isError: false);

        // Làm mới danh sách giao dịch
        ref.invalidate(transactionListProvider);
        
        // 🔄 TỐI ƯU HÓA: Thay vì invalidate làm mất state và chớp Shimmer ví,
        // ta gọi refreshWallets ngầm dưới background
        ref.read(walletNotifierProvider.notifier).refreshWallets();

        // Hiển thị thông báo chuyển khoản ngoài app
        try {
          final amt = double.tryParse(amountStr) ?? 0.0;
          final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);
          final formattedAmount = _formatMoney(amt, currencyCode);

          final title = 'Chuyển tiền';
          final body =
              'Chuyển $formattedAmount $currencySymbol từ ví "$sourceWalletName" sang ví "$targetWalletName".';

          await LocalNotificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
            title: title,
            body: body,
          );

          final userId = ref.read(currentUserProvider)?.id ?? '';
          if (userId.isNotEmpty) {
            final localNotif = await LocalNotificationStorage.createAndSave(
              userId: userId,
              type: 'transaction',
              title: title,
              body: body,
            );
            if (localNotif != null) {
              ref
                  .read(notificationNotifierProvider.notifier)
                  .addLocalNotification(localNotif);
            }
          }
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? colors.expenseRed : colors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
