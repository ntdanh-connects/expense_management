import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/entities/internal_transfer_record.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_card_item.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_screen_shimmer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/features/wallet/presentation/provider/internal_transfer_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/utils/currency_utils.dart';


final showHiddenWalletsProvider = StateProvider<bool>((ref) => false);

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  WalletEntity? _fromWallet;
  WalletEntity? _toWallet;
  String? _filterWalletName;
  DateTimeRange? _filterDateRange;
  final TextEditingController _amountController = TextEditingController();
  bool _isTransferring = false;

  bool _isInternalTransferExpanded = false;
  bool _isExternalTransferExpanded = false;

  final TextEditingController _payeeIdentifierController = TextEditingController();
  String? _fetchedPayeeId;
  String? _fetchedPayeeUserId;
  String? _fetchedPayeeName;
  String? _recipientWalletName;
  String? _fetchedToWalletId;
  bool _isSearchingPayee = false;
  bool _isQrScanUsed = false;

  WalletEntity? _selectedExternalSourceWallet;
  final TextEditingController _externalAmountController = TextEditingController();
  final TextEditingController _externalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
    // 🔄 Tự động đồng bộ hóa ngầm danh sách ví từ Backend ngay khi người dùng vào màn hình này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletNotifierProvider.notifier).refreshWallets();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeIdentifierController.dispose();
    _externalAmountController.dispose();
    _externalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletState = ref.watch(walletNotifierProvider);
    final transferState = ref.watch(internalTransferHistoryProvider);
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency));
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);

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
                            currencySymbol: AppConstant.getCurrencySymbol(wallet.currencyCode),
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

                // 🔁 2. CHUYỂN TIỀN NỘI BỘ (COLLAPSIBLE)
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
                                      ? displayedWallets.where((w) => w.currencyCode == _toWallet!.currencyCode).toList()
                                      : displayedWallets,
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
                                  items: _fromWallet != null
                                      ? displayedWallets.where((w) => w.currencyCode == _fromWallet!.currencyCode).toList()
                                      : displayedWallets,
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
                                    _fromWallet != null ? AppConstant.getCurrencySymbol(_fromWallet!.currencyCode) : currencySymbol,
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
                                final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
                                double? amt = double.tryParse(cleanString);
                                if (amt != null) {
                                  if (amt > 500000000) {
                                    amt = 500000000;
                                  }
                                  final formatted = NumberFormat('#,###', 'vi_VN').format(amt);
                                  _amountController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.fromPosition(TextPosition(offset: formatted.length)),
                                  );
                                }
                              },
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _amountController,
                            builder: (context, value, child) {
                              final cleanString = value.text.replaceAll(RegExp(r'[^0-9]'), '');
                              final double? amt = double.tryParse(cleanString);
                              if (amt == null || amt == 0) {
                                return const SizedBox.shrink();
                              }
                              final wordRepresentation = numberToVietnameseWords(amt);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
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

                          // Nút chuyển tiền
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isTransferring ? null : () => _executeTransfer(colors),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTransferring ? colors.primary.withOpacity(0.5) : colors.primary,
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
                ),
                const SizedBox(height: 20),

                // 🔁 3. CHUYỂN TIỀN ĐẾN NGƯỜI KHÁC (COLLAPSIBLE)
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
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
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
                                  icon: const Icon(Icons.contacts_rounded, size: 18),
                                  label: const Text(
                                    'Danh bạ',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary.withOpacity(0.1),
                                    foregroundColor: colors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                                        builder: (_) => const _SimpleQrScannerPage(),
                                      ),
                                    );
                                    if (qrString != null) {
                                      final extracted = _extractIdentifierFromQr(qrString);
                                      _payeeIdentifierController.text = extracted;
                                      await _lookupPayee(extracted, isQr: true);
                                    }
                                  },
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                                  label: const Text(
                                    'Quét QR',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary.withOpacity(0.1),
                                    foregroundColor: colors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                                      : () => _lookupPayee(_payeeIdentifierController.text, isQr: false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                              items: displayedWallets.where((w) => w.type != 'cash').toList(),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
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
                                  final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
                                  double? amt = double.tryParse(cleanString);
                                  if (amt != null) {
                                    if (amt > 500000000) {
                                      amt = 500000000;
                                    }
                                    final formatted = NumberFormat('#,###', 'vi_VN').format(amt);
                                    _externalAmountController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.fromPosition(TextPosition(offset: formatted.length)),
                                    );
                                  }
                                },
                              ),
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _externalAmountController,
                              builder: (context, value, child) {
                                final cleanString = value.text.replaceAll(RegExp(r'[^0-9]'), '');
                                final double? amt = double.tryParse(cleanString);
                                if (amt == null || amt == 0) {
                                  return const SizedBox.shrink();
                                }
                                final wordRepresentation = numberToVietnameseWords(amt);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
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
                                        content: Text('Vui lòng chọn ví nguồn để chuyển khoản!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final cleanAmountString = _externalAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                  final double? amount = double.tryParse(cleanAmountString);
                                  
                                  if (amount == null || amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng nhập số tiền chuyển hợp lệ!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (amount > _selectedExternalSourceWallet!.balance) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Số dư ví "${_selectedExternalSourceWallet!.name}" không đủ!'),
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
                                    'description': _externalNotesController.text.trim().isNotEmpty
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
                const SizedBox(height: 8),

                // Bộ lọc ví và ngày
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Wallet filter chip
                      _buildFilterChip(
                        context: context,
                        label: _filterWalletName ?? 'Tất cả ví',
                        icon: Icons.account_balance_wallet_rounded,
                        isActive: _filterWalletName != null,
                        onTap: () {
                          walletState.whenData((wallets) {
                            _showFilterWalletSelector(context, wallets);
                          });
                        },
                        onClear: _filterWalletName != null
                            ? () {
                                setState(() {
                                  _filterWalletName = null;
                                });
                              }
                            : null,
                        colors: colors,
                      ),
                      const SizedBox(width: 8),
                      // Date filter chip
                      _buildFilterChip(
                        context: context,
                        label: _filterDateRange == null
                            ? 'Tất cả ngày'
                            : '${DateFormat('dd/MM').format(_filterDateRange!.start)} - ${DateFormat('dd/MM').format(_filterDateRange!.end)}',
                        icon: Icons.calendar_today_rounded,
                        isActive: _filterDateRange != null,
                        onTap: () async {
                          final pickedRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: _filterDateRange,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.fromSeed(
                                    seedColor: colors.primary,
                                    primary: colors.primary,
                                    onPrimary: Colors.white,
                                    surface: colors.surface,
                                    onSurface: colors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedRange != null) {
                            setState(() {
                              _filterDateRange = pickedRange;
                            });
                          }
                        },
                        onClear: _filterDateRange != null
                            ? () {
                                setState(() {
                                  _filterDateRange = null;
                                });
                              }
                            : null,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // List lịch sử giao dịch
                transferState.when(
                  data: (transfersList) {
                    var filteredList = transfersList;
                    if (_filterWalletName != null) {
                      filteredList = filteredList.where((tx) =>
                          tx.fromWalletName == _filterWalletName ||
                          tx.toWalletName == _filterWalletName).toList();
                    }
                    if (_filterDateRange != null) {
                      final start = DateTime(_filterDateRange!.start.year, _filterDateRange!.start.month, _filterDateRange!.start.day);
                      final end = DateTime(_filterDateRange!.end.year, _filterDateRange!.end.month, _filterDateRange!.end.day, 23, 59, 59);
                      filteredList = filteredList.where((tx) =>
                          tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                          tx.date.isBefore(end.add(const Duration(seconds: 1)))).toList();
                    }

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'no_transfer_history'.tr(ref),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final tx = filteredList[index];
                        return _buildTransferHistoryItem(tx, colors, AppConstant.getCurrencySymbol(tx.currencyCode ?? 'VND'));
                      },
                    );
                  },
                  loading: () => const TransferHistoryShimmer(),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'load_transfer_history_error'.tr(ref),
                        style: TextStyle(color: colors.expenseRed),
                      ),
                    ),
                  ),
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
  Widget _buildTransferHistoryItem(InternalTransferRecord tx, AppColorsExtension colors, String currencySymbol) {
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
                  _formatDate(tx.date, timezoneOverride: tx.timezone),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${_formatMoney(tx.amount, tx.currencyCode)}$currencySymbol',
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
  void _executeTransfer(AppColorsExtension colors) async {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    setState(() {
      _isTransferring = true;
    });

    try {
      // Gọi thực thi logic ở Provider
      final errorKey = await ref.read(internalTransferHistoryProvider.notifier).executeTransfer(
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
        // Lưu thông tin ví trước khi reset state để hiển thị thông báo chính xác
        final sourceWalletName = _fromWallet?.name;
        final targetWalletName = _toWallet?.name;
        final currencyCode = _fromWallet?.currencyCode ?? 'VND';

        _amountController.clear();
        setState(() {
          _fromWallet = null;
          _toWallet = null;
        });
        _showSnackBar('transfer_success'.tr(ref), isError: false);

        // Dọn dẹp HTTP cache để các báo cáo/thống kê kéo dữ liệu mới
        ref.read(cacheStoreProvider).clean();
        // Làm mới danh sách giao dịch để cập nhật giao dịch chuyển tiền mới
        ref.invalidate(transactionListProvider);
        // Làm mới ví để cập nhật số dư
        ref.invalidate(walletNotifierProvider);

        // Hiển thị thông báo chuyển khoản ngoài app
        try {
          final amt = double.tryParse(amountStr) ?? 0.0;
          final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);
          final formattedAmount = _formatMoney(amt, currencyCode);
          
          final title = 'Chuyển tiền';
          final body = 'Chuyển $formattedAmount $currencySymbol từ ví "$sourceWalletName" sang ví "$targetWalletName".';

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
              ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
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

  String _formatDate(DateTime date, {String? timezoneOverride}) {
    final user = ref.read(currentUserProvider);
    final timezoneName = timezoneOverride ?? user?.timezone ?? 'Asia/Ho_Chi_Minh';
    
    // Sử dụng package timezone để tự động quy đổi múi giờ IANA động
    DateTime userDate;
    String formattedOffset = 'UTC';
    try {
      final location = tz.getLocation(timezoneName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      userDate = tzDateTime;
      
      // Định dạng offset hiển thị (ví dụ: UTC+07:00 hoặc UTC-05:00)
      final offsetMs = tzDateTime.timeZoneOffset.inMilliseconds;
      final offsetHours = (offsetMs / 3600000).truncate();
      final offsetMinutes = ((offsetMs.abs() % 3600000) / 60000).truncate();
      final sign = offsetHours >= 0 ? '+' : '-';
      final hoursStr = offsetHours.abs().toString().padLeft(2, '0');
      final minutesStr = offsetMinutes.toString().padLeft(2, '0');
      formattedOffset = 'UTC$sign$hoursStr:$minutesStr';
    } catch (_) {
      // Fallback về giờ UTC nếu có lỗi phân giải múi giờ
      userDate = date.toUtc();
    }
    
    final hour = userDate.hour.toString().padLeft(2, '0');
    final minute = userDate.minute.toString().padLeft(2, '0');
    final second = userDate.second.toString().padLeft(2, '0');
    final day = userDate.day.toString().padLeft(2, '0');
    final month = userDate.month.toString().padLeft(2, '0');
    final year = userDate.year;

    return '$hour:$minute:$second $day/$month/$year ($formattedOffset)';
  }

  String _normalizeIdentifier(String input) {
    String trimmed = input.trim();
    if (RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'USR$trimmed';
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
      final result = await ref.read(qrTransferProvider.notifier).decodeQrCode(normalized);
      if (result != null) {
        setState(() {
          _fetchedPayeeName = result['payee_name'];
          _fetchedPayeeId = result['payee_id']?.toString();
          _fetchedPayeeUserId = result['payee_user_id']?.toString();
          _recipientWalletName = result['recipient_wallet_name']?.toString();
          _fetchedToWalletId = result['to_wallet_id']?.toString();

          final showHidden = ref.read(showHiddenWalletsProvider);
          final wallets = ref.read(walletNotifierProvider).value ?? [];
          final displayed = showHidden ? wallets : wallets.where((w) => !w.isHidden).toList();
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
              content: Text('Không tìm thấy người thụ hưởng hoặc mã không hợp lệ!'),
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

      final internalPayees = payees.where((p) => p['payee_type'] == 'internal').toList();

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      final displayName = name.isEmpty ? 'Không xác định' : name;
                      final identifier = payee['identifier'] ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: payee['avatar_url'] != null
                              ? NetworkImage(payee['avatar_url'])
                              : null,
                          child: payee['avatar_url'] == null ? const Icon(Icons.person) : null,
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

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
    required AppColorsExtension colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isActive
        ? colors.primary.withOpacity(0.12)
        : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6));
    final textColor = isActive ? colors.primary : colors.textPrimary;
    final iconColor = isActive ? colors.primary : colors.textSecondary;
    final borderColor = isActive ? colors.primary.withOpacity(0.3) : colors.textSecondary.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: iconColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterWalletSelector(BuildContext context, List<WalletEntity> wallets) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.5,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lọc theo ví',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.all_inclusive_rounded, color: colors.primary, size: 20),
                      ),
                      title: const Text('Tất cả ví', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: _filterWalletName == null
                          ? Icon(Icons.check_circle_rounded, color: colors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _filterWalletName = null;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(height: 1),
                    ...wallets.map((wallet) {
                      final isSelected = _filterWalletName == wallet.name;
                      final walletColor = Color(
                        int.parse(wallet.color.replaceAll('#', 'FF'), radix: 16),
                      );
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: walletColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: walletColor,
                            size: 18,
                          ),
                        ),
                        title: Text(wallet.name),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colors.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            _filterWalletName = wallet.name;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

class TransferHistoryShimmer extends StatelessWidget {
  const TransferHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 70,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SimpleQrScannerPage extends StatefulWidget {
  const _SimpleQrScannerPage();

  @override
  State<_SimpleQrScannerPage> createState() => _SimpleQrScannerPageState();
}

class _SimpleQrScannerPageState extends State<_SimpleQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR người thụ hưởng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _isScanned = true;
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}