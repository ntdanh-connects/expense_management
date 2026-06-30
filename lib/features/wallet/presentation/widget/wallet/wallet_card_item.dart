import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

class WalletCardItem extends StatelessWidget {
  final WalletEntity wallet;
  final VoidCallback? onTap;
  final String currencySymbol;

  const WalletCardItem({
    super.key,
    required this.wallet,
    this.onTap,
    this.currencySymbol = 'đ',
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(wallet.color, wallet.name);



    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: wallet.isHidden ? 0.55 : 1.0,
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
                '${_formatMoney(wallet.balance, wallet.currencyCode)} $currencySymbol',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
  
              // Dòng dưới cùng: Sạch sẽ, không còn mã số/hết hạn thừa thãi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (wallet.isHidden)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.visibility_off_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ĐANG ẨN',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (wallet.isDefaultReceiving &&
                      (wallet.type == 'bank' ||
                       wallet.type == 'ewallet' ||
                       wallet.type == 'e-wallet'))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'NHẬN MẶC ĐỊNH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ],
          ),
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