import 'package:flutter/material.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletCardItem extends StatelessWidget {
  final WalletEntity wallet;
  final VoidCallback? onTap;

  const WalletCardItem({
    super.key,
    required this.wallet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(wallet.color, wallet.name);

    // Bốc 4 ký tự cuối của id làm số thẻ
    final lastFour = wallet.id.length >= 4
        ? wallet.id.substring(wallet.id.length - 4).toUpperCase()
        : '8842';

    // Mock ngày hết hạn dựa theo chữ cái đầu của ID
    final mockMonth = (wallet.id.hashCode % 12 + 1).toString().padLeft(2, '0');
    final mockYear = (28 + (wallet.id.hashCode % 5)).toString();
    final expiryDate = '$mockMonth/$mockYear';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dòng trên cùng: Tên & loại + Icon Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wallet.type == 'e-wallet' ? 'E-WALLET' : (wallet.type == 'bank' ? 'BANK' : 'CASH'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Logo tròn phát sáng màu trắng hoặc icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getWalletIcon(wallet.icon),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),

            // Số dư ví to rõ nét ở chính giữa
            Text(
              '${_formatMoney(wallet.balance)} đ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            // Dòng dưới cùng: Số thẻ ẩn danh & Hạn dùng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '**** $lastFour',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Hết hạn $expiryDate',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'piggy':
        return Icons.savings_rounded;
      case 'cash':
        return Icons.payments_rounded;
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
      case 'e-wallet':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  String _formatMoney(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';
    return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
  }

  Gradient _getGradient(String colorHex, String name) {
    final hexColor = colorHex.replaceAll('#', '');
    Color baseColor;
    try {
      baseColor = hexColor.length == 6
          ? Color(int.parse('FF$hexColor', radix: 16))
          : const Color(0xFF6366F1); // fallback
    } catch (_) {
      baseColor = const Color(0xFF6366F1);
    }

    return LinearGradient(
      colors: [baseColor, Color.alphaBlend(Colors.black.withOpacity(0.22), baseColor)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}