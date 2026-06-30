import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import '../qr_scanner/simple_qr_scanner_page.dart';

class WalletExternalTransferSection extends ConsumerStatefulWidget {
  final List<WalletEntity> displayedWallets;
  final Color panelBg;

  const WalletExternalTransferSection({
    super.key,
    required this.displayedWallets,
    required this.panelBg,
  });

  @override
  ConsumerState<WalletExternalTransferSection> createState() =>
      _WalletExternalTransferSectionState();
}

class _WalletExternalTransferSectionState
    extends ConsumerState<WalletExternalTransferSection> {
  bool _isExternalTransferExpanded = false;
  final TextEditingController _payeeIdentifierController =
      TextEditingController();
  String? _fetchedPayeeId;
  String? _fetchedPayeeUserId;
  String? _fetchedPayeeName;
  String? _recipientWalletName;
  String? _fetchedToWalletId;
  bool _isSearchingPayee = false;
  bool _isQrScanUsed = false;

  WalletEntity? _selectedExternalSourceWallet;
  final TextEditingController _externalAmountController =
      TextEditingController();
  final TextEditingController _externalNotesController =
      TextEditingController();

  @override
  void dispose() {
    _payeeIdentifierController.dispose();
    _externalAmountController.dispose();
    _externalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  _isExternalTransferExpanded = !_isExternalTransferExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: colors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chuyển tiền đến người khác',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExternalTransferExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),

            if (_isExternalTransferExpanded) ...[
              const SizedBox(height: 24),

              // Nhập mã định danh người nhận
              Text(
                'payee_info_title'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.textSecondary.withOpacity(0.12),
                  ),
                ),
                child: TextField(
                  controller: _payeeIdentifierController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Mã định danh (ví dụ: USR123456)',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (val) {
                    if (_fetchedPayeeName != null) {
                      setState(() {
                        _isQrScanUsed = false;
                        _fetchedPayeeName = null;
                        _fetchedPayeeId = null;
                        _fetchedPayeeUserId = null;
                        _recipientWalletName = null;
                        _fetchedToWalletId = null;
                        _selectedExternalSourceWallet = null;
                        _externalAmountController.clear();
                        _externalNotesController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Nút Chọn danh bạ
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPayeeSelector(context),
                      icon: const Icon(
                        Icons.contacts_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Danh bạ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary.withOpacity(0.1),
                        foregroundColor: colors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Quét mã QR
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final qrString = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SimpleQrScannerPage(),
                          ),
                        );
                        if (qrString != null) {
                          final extracted = _extractIdentifierFromQr(qrString);
                          _payeeIdentifierController.text = extracted;
                          await _lookupPayee(extracted, isQr: true);
                        }
                      },
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Quét QR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary.withOpacity(0.1),
                        foregroundColor: colors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Kiểm tra
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSearchingPayee
                          ? null
                          : () => _lookupPayee(
                                _payeeIdentifierController.text,
                                isQr: false,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSearchingPayee
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'check'.tr(ref),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              if (_fetchedPayeeName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.incomeGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.incomeGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: colors.incomeGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Người thụ hưởng: $_fetchedPayeeName',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_recipientWalletName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ví nhận: $_recipientWalletName',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Chọn ví nguồn
                _buildWalletDropdown(
                  label: 'Chọn ví nguồn để chuyển',
                  value: _selectedExternalSourceWallet,
                  items: widget.displayedWallets
                      .where((w) => w.type != 'cash')
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedExternalSourceWallet = val;
                    });
                  },
                  colors: colors,
                  labelSize: 15,
                ),
                const SizedBox(height: 20),

                // Ô nhập số tiền
                Text(
                  'Nhập số tiền chuyển',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                    controller: _externalAmountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập số tiền',
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                      suffixText: 'đ',
                      suffixStyle: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
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
                        _externalAmountController.value = TextEditingValue(
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
                  valueListenable: _externalAmountController,
                  builder: (context, value, child) {
                    final cleanString = value.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final double? amt = double.tryParse(cleanString);
                    if (amt == null || amt == 0) {
                      return const SizedBox.shrink();
                    }
                    final wordRepresentation =
                        formatNumberToWords(amt, localeCode);
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
                const SizedBox(height: 20),

                // Lời nhắn chuyển tiền
                Text(
                  'Lời nhắn chuyển tiền',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                    controller: _externalNotesController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nhập lời nhắn chuyển tiền...',
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.6),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Tiếp tục để chuyển tiếp đến màn hình xác nhận chuyển khoản
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedExternalSourceWallet == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng chọn ví nguồn để chuyển khoản!',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final cleanAmountString = _externalAmountController.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                      final double? amount = double.tryParse(cleanAmountString);

                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng nhập số tiền chuyển hợp lệ!',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (amount > _selectedExternalSourceWallet!.balance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Số dư ví "${_selectedExternalSourceWallet!.name}" không đủ!',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final mappedPayee = {
                        'payee_id': _fetchedPayeeId,
                        'type': 'internal',
                        'payee_user_id': _fetchedPayeeUserId,
                        'identifier': _payeeIdentifierController.text.trim(),
                        'payee_name': _fetchedPayeeName,
                        'recipient_wallet_name': _recipientWalletName,
                        'from_wallet_id': _selectedExternalSourceWallet!.id,
                        'amount': amount,
                        'description': _externalNotesController.text
                                .trim()
                                .isNotEmpty
                            ? _externalNotesController.text.trim()
                            : 'Chuyển tiền cho $_fetchedPayeeName',
                        'to_wallet_id': _fetchedToWalletId,
                        'is_qr': _isQrScanUsed,
                      };
                      context.push('/add-transaction', extra: mappedPayee);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Tiếp tục',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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

  String _normalizeIdentifier(String input) {
    String trimmed = input.trim();
    if (RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'USR${trimmed}';
    }
    if (trimmed.toLowerCase().startsWith('usr')) {
      return 'USR${trimmed.substring(3)}';
    }
    return trimmed;
  }

  String _extractIdentifierFromQr(String qrString) {
    final trimmed = qrString.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final Map<String, dynamic> data = json.decode(trimmed);
        if (data['identifier'] != null) {
          return data['identifier'].toString();
        }
      } catch (_) {}
    }
    if (trimmed.contains('?')) {
      try {
        final uri = Uri.parse(trimmed);
        final id = uri.queryParameters['id'];
        if (id != null) {
          return id;
        }
      } catch (_) {}
    }
    return trimmed;
  }

  Future<void> _lookupPayee(String identifier, {bool isQr = false}) async {
    final normalized = _normalizeIdentifier(identifier);
    if (normalized.isEmpty) return;

    _payeeIdentifierController.text = normalized;

    setState(() {
      _isQrScanUsed = isQr;
      _isSearchingPayee = true;
      _fetchedPayeeName = null;
      _fetchedPayeeId = null;
      _fetchedPayeeUserId = null;
      _recipientWalletName = null;
      _fetchedToWalletId = null;
      _selectedExternalSourceWallet = null;
      _externalAmountController.clear();
      _externalNotesController.clear();
    });

    try {
      final result = await ref
          .read(qrTransferProvider.notifier)
          .decodeQrCode(normalized);
      if (result != null) {
        setState(() {
          _fetchedPayeeName = result['payee_name'];
          _fetchedPayeeId = result['payee_id']?.toString();
          _fetchedPayeeUserId = result['payee_user_id']?.toString();
          _recipientWalletName = result['recipient_wallet_name']?.toString();
          _fetchedToWalletId = result['to_wallet_id']?.toString();

          final showHidden = ref.read(showHiddenWalletsProvider);
          final wallets = ref.read(walletNotifierProvider).value ?? [];
          final displayed = showHidden
              ? wallets
              : wallets.where((w) => !w.isHidden).toList();
          final eligible = displayed.where((w) => w.type != 'cash').toList();
          if (eligible.isNotEmpty) {
            _selectedExternalSourceWallet = eligible.firstWhere(
              (w) => w.type == 'bank',
              orElse: () => eligible.first,
            );
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không tìm thấy người thụ hưởng hoặc mã không hợp lệ!',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tra cứu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingPayee = false;
        });
      }
    }
  }

  void _showPayeeSelector(BuildContext context) async {
    final colors = context.colors;
    setState(() {
      _isSearchingPayee = true;
    });

    try {
      final notifier = ref.read(qrTransferProvider.notifier);
      final result = await notifier.fetchPayees(perPage: 50);
      final List<dynamic> payees = result?['data'] ?? [];

      if (!mounted) return;
      setState(() {
        _isSearchingPayee = false;
      });

      if (payees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danh bạ người nhận trống!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final internalPayees = payees
          .where((p) => p['payee_type'] == 'internal')
          .toList();

      if (internalPayees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có người nhận nội bộ nào trong danh bạ!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn người nhận',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: internalPayees.length,
                    itemBuilder: (context, idx) {
                      final payee = internalPayees[idx];
                      final name = payee['payee_name']?.toString().trim() ?? '';
                      final displayName = name.isEmpty
                          ? 'Không xác định'
                          : name;
                      final identifier = payee['identifier'] ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: payee['avatar_url'] != null
                              ? NetworkImage(payee['avatar_url'])
                              : null,
                          child: payee['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          identifier,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _lookupPayee(identifier, isQr: false);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isSearchingPayee = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lấy danh sách người nhận: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
