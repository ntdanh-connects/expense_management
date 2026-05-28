import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart'; // Import extension của ní

class WalletEmptyState extends StatelessWidget {
  const WalletEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 72, color: appColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy chiếc ví nào ní ơi!',
            style: TextStyle(
              color: appColors.textPrimary, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy chạm nút + dưới thanh trượt để kích nổ tạo ví.',
            style: TextStyle(
              color: appColors.textSecondary, 
              fontSize: 13
            ),
          ),
        ],
      ),
    );
  }
}