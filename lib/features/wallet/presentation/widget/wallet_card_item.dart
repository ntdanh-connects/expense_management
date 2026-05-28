import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart'; // ⚡ Import tệp extension của ní nhen
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
    // 🎨 HÚP EXTENSION QUÝ TỘC CỦA NÍ: Lôi bộ màu tương ứng ra xài phẳng lỳ
    final appColors = context.colors;

    // 🔮 ẢO THUẬT HEX COLOR: Bóc màu BE gửi về sang Color đối tượng
    final hexColor = wallet.color.replaceAll('#', '');
    final Color neonColor = hexColor.length == 6
        ? Color(int.parse('FF$hexColor', radix: 16))
        : appColors.primary; // ⚡ BẢO HIỂM: Lấy màu primary hệ thống nếu BE nhảy lỗi

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      splashColor: neonColor.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appColors.surface, // ⚡ ĐỒNG BỘ THEME: Ăn theo màu surface của hệ theme (Light/Dark tự co giãn)
          borderRadius: BorderRadius.circular(24),
          // ✨ VIỀN PHÁT SÁNG NEON MỜ ẢO CHÍNH CHỦ THEO MÀU VÍ
          border: Border.all(color: neonColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: neonColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            // Cụm vòng tròn bọc Icon phát sáng dải màu Neon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: neonColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getWalletIcon(wallet.type),
                color: neonColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // Tên Ví và Loại ví phẳng lỳ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appColors.textPrimary, // ⚡ ĐỒNG BỘ THEME TEXT
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet.type.toUpperCase(),
                    style: TextStyle(
                      color: appColors.textSecondary, // ⚡ ĐỒNG BỘ THEME TEXT PHỤ
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Số dư ví thật giật số độc quyền VND
            Text(
              '${_formatMoney(wallet.balance)} ₫',
              style: TextStyle(
                color: neonColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.wb_sunny_rounded; 
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e-wallet':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  String _formatMoney(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]},';
    return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
  }
}