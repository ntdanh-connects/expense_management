import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({super.key});

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

  final List<Map<String, String>> _colorsList = [
    {'name': 'Indigo', 'hex': '#4C4DDC'},
    {'name': 'Sage', 'hex': '#D2E8DA'},
    {'name': 'Peach', 'hex': '#FCDCD4'},
    {'name': 'Yellow', 'hex': '#FFCE73'},
    {'name': 'Lavender', 'hex': '#E2DDFD'},
    {'name': 'Mint', 'hex': '#A9F0D1'},
  ];

  final List<Map<String, dynamic>> _iconsList = [
    {'key': 'cash', 'icon': Icons.payments_rounded},
    {'key': 'bank', 'icon': Icons.account_balance_rounded},
    {'key': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'key': 'card', 'icon': Icons.credit_card_rounded},
    {'key': 'piggy', 'icon': Icons.savings_rounded},
    {'key': 'bag', 'icon': Icons.shopping_bag_rounded},
    {'key': 'car', 'icon': Icons.directions_car_rounded},
    {'key': 'home', 'icon': Icons.home_rounded},
    {'key': 'food', 'icon': Icons.restaurant_rounded},
    {'key': 'plane', 'icon': Icons.flight_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _walletName = _nameController.text.trim().isEmpty
            ? 'Ví mới của tôi'
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
    
    // Tự tính dải màu cho Live Card Preview dựa trên màu sắc được chọn
    final hexColor = _selectedColor.replaceAll('#', '');
    Color baseColor;
    try {
      baseColor = hexColor.length == 6
          ? Color(int.parse('FF$hexColor', radix: 16))
          : colors.primary;
    } catch (_) {
      baseColor = colors.primary;
    }
    final Color color2 = Color.alphaBlend(Colors.black.withOpacity(0.22), baseColor);
    final cardGradient = LinearGradient(
      colors: [baseColor, color2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

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
          'Thêm ví mới',
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
            Center(
              child: Container(
                width: double.infinity,
                height: 180,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tên ví',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _walletName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getIconData(_selectedIcon),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư khởi tạo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatMoney(_initialBalance)} đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  suffixIcon: Container(
                    alignment: Alignment.centerRight,
                    width: 20,
                    child: Text(
                      'đ',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
              itemCount: _iconsList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final item = _iconsList[index];
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
                itemCount: _colorsList.length,
                itemBuilder: (context, idx) {
                  final c = _colorsList[idx];
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

            // 🚀 7. NÚT TẠO VÍ ⊕
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tạo ví ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline_rounded,
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

  IconData _getIconData(String iconKey) {
    switch (iconKey) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'piggy':
        return Icons.savings_rounded;
      case 'bag':
        return Icons.shopping_bag_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'plane':
        return Icons.flight_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  void _handleCreateWallet(AppColorsExtension colors) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Vui lòng nhập tên ví!', isError: true);
      return;
    }

    try {
      final newId = 'wallet-${DateTime.now().millisecondsSinceEpoch}';
      final newWallet = WalletEntity(
        id: newId,
        name: name,
        balance: _initialBalance,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      await ref.read(walletRepositoryProvider).createWallet(newWallet);
      
      if (!context.mounted) return;
      context.pop(); // Quay lại WalletScreen
      
      // Hiển thị snackbar ở màn hình cũ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tạo ví mới thành công!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.incomeGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      _showSnackBar('Không thể tạo ví: $e', isError: true);
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

  String _formatMoney(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';
    return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
  }
}
