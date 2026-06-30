import 'package:flutter/material.dart';
import '../shared/wallet_constants.dart';

class WalletPreviewCard extends StatelessWidget {
  final String walletName;
  final double balance;
  final String selectedIcon;
  final String selectedColor;
  final Color primaryColor;
  final String currencySymbol;

  const WalletPreviewCard({
    super.key,
    required this.walletName,
    required this.balance,
    required this.selectedIcon,
    required this.selectedColor,
    required this.primaryColor,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    // Tách mã màu Hex
    final hexColor = selectedColor.replaceAll('#', '');
    Color baseColor;
    try {
      baseColor = hexColor.length == 6
          ? Color(int.parse('FF$hexColor', radix: 16))
          : primaryColor;
    } catch (_) {
      baseColor = primaryColor;
    }
    
    final Color color2 = Color.alphaBlend(Colors.black.withOpacity(0.22), baseColor);
    final cardGradient = LinearGradient(
      colors: [baseColor, color2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Center(
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
                        walletName.toUpperCase(),
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
                    WalletUIConstants.getIconData(selectedIcon),
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
                  '${_formatMoney(balance)} $currencySymbol',
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
    );
  }

  String _formatMoney(double value) {
    final bool isZeroDecimal = currencySymbol == 'đ' || currencySymbol == '₫' || currencySymbol == '¥';
    
    if (isZeroDecimal) {
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
}
