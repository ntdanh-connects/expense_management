import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; //[cite: 22]
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Bảo mật & Sinh trắc học')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.authCardBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: colors.profileSecurity, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2FA ACTIVE', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                    Text('Tài khoản bảo mật cao (85%)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Các cấu hình switch bảo mật có thể thêm tại đây tương ứng dữ liệu của Auth
        ],
      ),
    );
  }
}