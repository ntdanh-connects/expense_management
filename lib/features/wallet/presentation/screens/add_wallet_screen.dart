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
    }

    _nameController.addListener(() {
      setState(() {
        _walletName = _nameController.text.trim().isEmpty
            ? (widget.walletToEdit != null ? widget.walletToEdit!.name : 'Ví mới của tôi')
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
          widget.walletToEdit != null ? 'Chỉnh sửa ví' : 'Thêm ví mới',
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
            ),
            const SizedBox(height: 28),

            // ✍️ 2. Ô NHẬP TÊN VÍ
            Text(
              'Tên ví',
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
                  hintText: 'Nhập tên ví (ví dụ: Ví Tiền Mặt)',
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
            Text(
              'Số dư ban đầu',
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
                color: widget.walletToEdit != null
                    ? (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFE5E7EB))
                    : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _balanceController,
                enabled: widget.walletToEdit == null, // 🔒 Khóa không cho chỉnh sửa số dư khi edit ví
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: widget.walletToEdit != null
                      ? colors.textSecondary.withOpacity(0.8)
                      : colors.textPrimary,
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
                        if (widget.walletToEdit != null) ...[
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: colors.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'đ',
                          style: TextStyle(
                            color: widget.walletToEdit != null
                                ? colors.textSecondary.withOpacity(0.8)
                                : colors.textPrimary,
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

            // 📁 4. CHỌN LOẠI VÍ
            Text(
              'Chọn loại ví',
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
                  label: 'Tiền mặt',
                  icon: Icons.payments_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 10),
                _buildTypeChip(
                  key: 'bank',
                  label: 'Ngân hàng',
                  icon: Icons.account_balance_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 10),
                _buildTypeChip(
                  key: 'e-wallet',
                  label: 'Ví điện tử',
                  icon: Icons.qr_code_scanner_rounded,
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🎨 5. CHỌN BIỂU TƯỢNG (GRID 2x5)
            Text(
              'Chọn biểu tượng',
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
              'Chọn màu sắc',
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
                      widget.walletToEdit != null ? 'Lưu thay đổi ' : 'Tạo ví ',
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
                         widget.walletToEdit != null ? 'Đang thay đổi ví' : ' Đang tạo ví',
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
      _showSnackBar('Vui lòng nhập tên ví!', isError: true);
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
                widget.walletToEdit != null ? 'Cập nhật ví của bạn' : 'Thêm vào Ví của bạn',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.walletToEdit != null
                    ? 'Xác nhận thông tin thay đổi để cập nhật hệ thống'
                    : 'Xác nhận thông tin ví mới để liên kết hệ thống',
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
                      '${_formatMoney(_initialBalance)} đ',
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
                    widget.walletToEdit != null ? 'Lưu thay đổi' : 'Thêm ví mới',
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
                  'Hủy bỏ',
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
                    widget.walletToEdit != null ? 'Xác nhận chỉnh sửa' : 'Xác nhận bảo mật',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.walletToEdit != null
                    ? 'Vui lòng vuốt thanh bên dưới từ trái sang phải để đồng ý lưu các thay đổi cho ví "$_walletName".'
                    : 'Vui lòng vuốt thanh bên dưới từ trái sang phải để đồng ý tạo ví "$_walletName" với số dư ban đầu là ${_formatMoney(_initialBalance)} đ.',
                style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              
              // 🕹️ Gọi Thanh Trượt Xác Nhận Vuốt Chống Bấm Nhầm
              SwipeToConfirmButton(
                text: widget.walletToEdit != null ? 'Trượt để lưu thay đổi' : 'Trượt để tạo ví',
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
        isHidden: false,
        availableBalance: _initialBalance.toStringAsFixed(0),
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
                ? 'Cập nhật thông tin ví thành công!'
                : 'Tạo ví mới thành công!',
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
                widget.walletToEdit != null ? 'Lỗi chỉnh sửa ví' : 'Lỗi tạo ví',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            widget.walletToEdit != null
                ? 'Không thể gửi yêu cầu chỉnh sửa thông tin ví lên Server.\n\nChi tiết lỗi từ hệ thống:\n$error'
                : 'Không thể gửi yêu cầu tạo ví lên Server.\n\nChi tiết lỗi từ hệ thống:\n$error',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Đồng ý',
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

  String _formatMoney(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';
    return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
  }
}

