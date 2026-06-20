import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_constants.dart';
import 'package:expense_management/features/wallet/presentation/widget/swipe_to_confirm_button.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_preview_card.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/widget/vcb_rate_reference_widget.dart';


class AddWalletScreen extends ConsumerStatefulWidget {
  final WalletEntity? walletToEdit;
  const AddWalletScreen({super.key, this.walletToEdit});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  String _walletName = 'Ví mới của tôi';
  double _initialBalance = 0;

  // Trạng thái custom lựa chọn của người dùng
  String _selectedType = 'cash'; // cash, bank, e-wallet
  String _selectedIcon = 'wallet'; // wallet, bank, card, piggy, cash, bag, car, home, food, plane
  String _selectedColor = '#4C4DDC'; // Royal Indigo làm mặc định
  bool _isLoading = false; // Trạng thái loading khi call API tạo ví
  bool _isHidden = false; // Trạng thái ẩn ví trên Dashboard
  bool _isDefaultReceiving = false; // Trạng thái nhận mặc định
  String _selectedCurrency = 'VND';
  bool _selectedCurrencyInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.walletToEdit != null) {
      _walletName = widget.walletToEdit!.name;
      _nameController.text = widget.walletToEdit!.name;
      _initialBalance = widget.walletToEdit!.balance;
      _balanceController.text = widget.walletToEdit!.balance.toStringAsFixed(0);
      _selectedType = widget.walletToEdit!.type;
      _selectedIcon = widget.walletToEdit!.icon;
      _selectedColor = widget.walletToEdit!.color;
      _isHidden = widget.walletToEdit!.isHidden;
      _selectedCurrency = widget.walletToEdit!.currencyCode;
      _selectedCurrencyInitialized = true;
      _isDefaultReceiving = widget.walletToEdit!.isDefaultReceiving;
    } else {
      // Đợi frame đầu tiên vẽ xong để ref đã sẵn sàng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _walletName = 'my_new_wallet'.tr(ref);
            _selectedCurrency = 'VND';
          });
        }
      });
    }

    _nameController.addListener(() {
      setState(() {
        _walletName = _nameController.text.trim().isEmpty
            ? (widget.walletToEdit != null ? widget.walletToEdit!.name : 'my_new_wallet'.tr(ref))
            : _nameController.text.trim();
      });
    });
    _balanceController.addListener(() {
      setState(() {
        _initialBalance = double.tryParse(_balanceController.text.trim()) ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final optionsAsync = ref.watch(preferenceOptionsProvider);

    return Stack(
      children: [
        Scaffold(
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
          widget.walletToEdit != null ? 'edit_wallet'.tr(ref) : 'add_new_wallet'.tr(ref),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💳 1. THẺ VÍ LIVE CARD PREVIEW (DỰ PHÒNG THAY ĐỔI THEO THỜI GIAN THỰC)
            WalletPreviewCard(
              walletName: _walletName,
              balance: _initialBalance,
              selectedIcon: _selectedIcon,
              selectedColor: _selectedColor,
              primaryColor: colors.primary,
              currencySymbol: AppConstant.getCurrencySymbol(_selectedCurrency),
            ),
            const SizedBox(height: 28),

            // ✍️ 2. Ô NHẬP TÊN VÍ
            Text(
              'wallet_name'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
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
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'enter_wallet_name_hint'.tr(ref),
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 💰 3. Ô NHẬP SỐ DƯ BAN ĐẦU
            if (widget.walletToEdit != null) ...[
              Text(
                'initial_balance'.tr(ref),
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
                  color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _balanceController,
                  enabled: false, // 🔒 Khóa không cho chỉnh sửa số dư khi edit ví
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: colors.textSecondary.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    suffixIcon: Container(
                      alignment: Alignment.centerRight,
                      width: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: colors.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppConstant.getCurrencySymbol(ref.watch(currentUserProvider)?.currency),
                            style: TextStyle(
                              color: colors.textSecondary.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 📁 4. CHỌN LOẠI VÍ
            Text(
              'select_wallet_type'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTypeChip(
                  key: 'cash',
                  label: 'wallet_type_cash'.tr(ref),
                  icon: Icons.payments_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 10),
                _buildTypeChip(
                  key: 'bank',
                  label: 'wallet_type_bank'.tr(ref),
                  icon: Icons.account_balance_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 10),
                _buildTypeChip(
                  key: 'e-wallet',
                  label: 'wallet_type_ewallet'.tr(ref),
                  icon: Icons.qr_code_scanner_rounded,
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🎨 5. CHỌN BIỂU TƯỢNG (GRID 2x5)
            Text(
              'select_icon'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: WalletUIConstants.iconsList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final item = WalletUIConstants.iconsList[index];
                final String key = item['key'];
                final IconData iconData = item['icon'];
                final isSelected = _selectedIcon == key;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = key;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withOpacity(0.12)
                          : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? colors.primary : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? colors.primary : colors.textSecondary,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 🔴 6. CHỌN MÀU SẮC
            Text(
              'select_color'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: WalletUIConstants.colorsList.length,
                itemBuilder: (context, idx) {
                  final c = WalletUIConstants.colorsList[idx];
                  final hex = c['hex']!;
                  final isSelected = _selectedColor == hex;
                  final colorVal = Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = hex;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : colors.textPrimary,
                                width: 3.0,
                              )
                            : Border.all(color: Colors.transparent),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: colorVal.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),

            // 👁️ 6.5. ẨN VÍ KHỎI DASHBOARD (SWITCH)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHidden 
                      ? colors.primary.withOpacity(0.3) 
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isHidden 
                          ? colors.primary.withOpacity(0.12) 
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _isHidden ? colors.primary : colors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'hide_wallet_from_dashboard'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'hide_wallet_from_dashboard_desc'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isHidden,
                    activeColor: colors.primary,
                    activeTrackColor: colors.primary.withOpacity(0.3),
                    onChanged: (val) {
                      setState(() {
                        _isHidden = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // 📥 6.6. ĐẶT LÀM VÍ NHẬN MẶC ĐỊNH (SWITCH/BADGE)
            if (widget.walletToEdit != null &&
                (_selectedType == 'bank' || _selectedType == 'e-wallet' || _selectedType == 'ewallet')) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDefaultReceiving
                        ? colors.incomeGreen.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isDefaultReceiving
                            ? colors.incomeGreen.withOpacity(0.12)
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isDefaultReceiving
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _isDefaultReceiving ? colors.incomeGreen : colors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'set_as_default_receiving'.tr(ref),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'default_receiving_wallet_hint'.tr(ref),
                            style: TextStyle(
                              color: colors.textSecondary.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isDefaultReceiving,
                      activeColor: colors.incomeGreen,
                      activeTrackColor: colors.incomeGreen.withOpacity(0.3),
                      onChanged: _isDefaultReceiving
                          ? null // Đã bật rồi thì không cho tự gạt tắt về false
                          : (val) {
                              _executeSetDefaultReceiving(colors);
                            },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

             // 🚀 7. NÚT SUBMIT ⊕
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _handleCreateWallet(colors),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.walletToEdit != null ? '${'save_changes'.tr(ref)} ' : '${'create_wallet'.tr(ref)} ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      widget.walletToEdit != null
                          ? Icons.save_rounded
                          : Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
        if (_isLoading)
          AbsorbPointer(
            child: Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                         widget.walletToEdit != null ? 'updating_wallet'.tr(ref) : 'creating_wallet'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Widget vẽ các Chip loại ví custom
  Widget _buildTypeChip({
    required String key,
    required String label,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    final isSelected = _selectedType == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withOpacity(0.12)
                : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateWallet(AppColorsExtension colors) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('please_enter_wallet_name'.tr(ref), isError: true);
      return;
    }

    // Modern Android & iOS styles. By default, let's show Android Style with Swipe-to-confirm,
    // and easily allow the user to switch to iOS Style by commenting/uncommenting below:
    
    // Phong cách 1: Android Material 3 Swipe to Confirm (Trượt để xác nhận)
    _showAndroidConfirmSheet(context, colors);
    
    // Phong cách 2: iOS Cupertino Apple Wallet Sheet (Nhấn để xác nhận kiểu Apple)
    // _showIOSConfirmSheet(context, colors);
  }

  void _showIOSConfirmSheet(BuildContext context, AppColorsExtension colors) {
    HapticFeedback.mediumImpact(); // Rung nhẹ tạo cảm giác cơ học cao cấp
    final hexColor = _selectedColor.replaceAll('#', '');
    final Color cardColor = hexColor.length == 6
        ? Color(int.parse('FF$hexColor', radix: 16))
        : colors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.52,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.walletToEdit != null ? 'update_your_wallet'.tr(ref) : 'add_to_your_wallet'.tr(ref),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.walletToEdit != null
                    ? 'confirm_update_info_desc'.tr(ref)
                    : 'confirm_new_wallet_desc'.tr(ref),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              
              // 💳 Thẻ xem trước thu nhỏ
              Container(
                height: 100,
                width: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, Color.alphaBlend(Colors.black.withOpacity(0.2), cardColor)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _walletName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(WalletUIConstants.getIconData(_selectedIcon), color: Colors.white, size: 16),
                      ],
                    ),
                    Text(
                      '${_formatMoney(_initialBalance, _selectedCurrency)} ${AppConstant.getCurrencySymbol(_selectedCurrency)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // 🔘 Apple-style primary action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    _executeCreateWallet(colors);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.walletToEdit != null ? 'save_changes'.tr(ref) : 'add_new_wallet'.tr(ref),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'discard'.tr(ref),
                  style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showAndroidConfirmSheet(BuildContext context, AppColorsExtension colors) {
    HapticFeedback.mediumImpact(); // Rung nhẹ cơ học cực sướng
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    widget.walletToEdit != null ? Icons.edit_note_rounded : Icons.security_rounded,
                    color: colors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.walletToEdit != null ? 'confirm_edit'.tr(ref) : 'confirm_security'.tr(ref),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.walletToEdit != null
                    ? 'swipe_to_save_desc'.tr(ref).replaceAll('{name}', _walletName)
                    : 'swipe_to_create_desc'.tr(ref).replaceAll('{name}', _walletName).replaceAll('{balance}', '${_formatMoney(_initialBalance, _selectedCurrency)} ${AppConstant.getCurrencySymbol(_selectedCurrency)}'),
                style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              
              // 🕹️ Gọi Thanh Trượt Xác Nhận Vuốt Chống Bấm Nhầm
              SwipeToConfirmButton(
                text: widget.walletToEdit != null ? 'swipe_to_save'.tr(ref) : 'swipe_to_create'.tr(ref),
                activeColor: colors.primary,
                onConfirmed: () async {
                  HapticFeedback.vibrate(); // Báo thành công bằng nhịp rung nhẹ đặc biệt
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _executeCreateWallet(colors);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeCreateWallet(AppColorsExtension colors) async {
    final name = _nameController.text.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateWalletRequest(
        name: name,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
        isHidden: _isHidden,
        availableBalance: null,
        currencyCode: _selectedCurrency,
      );

      // 🚀 Gọi API thực tế thông qua Use Cases (Tạo mới hoặc Cập nhật)
      if (widget.walletToEdit != null) {
        await ref.read(updateWalletUseCaseProvider).execute(widget.walletToEdit!.id, request);
      } else {
        await ref.read(createWalletUseCaseProvider).execute(request);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (!context.mounted) return;
      context.pop(); // Quay lại WalletScreen
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.walletToEdit != null
                ? 'update_wallet_success'.tr(ref)
                : 'create_wallet_success'.tr(ref),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.incomeGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 🚨 Bắt lỗi đàng hoàng, hiển thị Dialog thông báo lỗi chi tiết từ Server
      _showErrorDialog(e.toString(), colors);
    }
  }

  void _executeSetDefaultReceiving(AppColorsExtension colors) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(setDefaultReceivingWalletUseCaseProvider).execute(widget.walletToEdit!.id);
      setState(() {
        _isDefaultReceiving = true;
        _isLoading = false;
      });
      if (!mounted) return;
      _showSnackBar('set_default_receiving_success'.tr(ref), isError: false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      _showErrorDialog(e.toString(), colors);
    }
  }

  void _showErrorDialog(String error, AppColorsExtension colors) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colors.expenseRed, size: 28),
              const SizedBox(width: 10),
              Text(
                widget.walletToEdit != null ? 'edit_wallet_error'.tr(ref) : 'create_wallet_error'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            widget.walletToEdit != null
                ? 'edit_wallet_error_desc'.tr(ref).replaceAll('{error}', error)
                : 'create_wallet_error_desc'.tr(ref).replaceAll('{error}', error),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ok'.tr(ref),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  String _formatMoney(double value, [String? currencyCode]) {
    return AppConstant.formatMoney(value, currencyCode ?? _selectedCurrency);
  }
  Widget _buildDropdownField<T>({
    required AppColorsExtension colors,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.04) 
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_outlined, color: colors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isDense: true,
                    isExpanded: true,
                    disabledHint: Text(value.toString()),
                    dropdownColor: colors.surface,
                    style: TextStyle(
                      color: onChanged == null ? colors.textSecondary.withOpacity(0.8) : colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
