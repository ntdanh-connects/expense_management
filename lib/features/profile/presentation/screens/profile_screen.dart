// import 'package:flutter/material.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return  Scaffold(
//       body: Center(
//         child: Text('No Data'),
//         child: Text('Wating update'),
//       ),
//     );
//   }
// }

import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/wallet_card.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    // Đồng bộ dữ liệu người dùng dùng chung từ hệ thống Auth qua currentUserProvider
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tài khoản',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KHỐI QUẢN LÝ VÍ & TÀI KHOẢN ---
            Text(
              'Quản lý ví & Tài khoản',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const WalletCard(
              title: 'Vietcombank',
              subtitle: '•••• 8888',
              icon: Icons.account_balance_rounded,
              iconColor: Colors.blueAccent,
            ),
            const SizedBox(height: 12),
            const WalletCard(
              title: 'Ví chính Capital',
              subtitle: '25.500.000 đ',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: Colors.green,
            ),

            const SizedBox(height: 24),

            // --- KHỐI CÀI ĐẶT HỆ THỐNG ---
            Text(
              'Cài đặt hệ thống',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: colors.authCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: Colors.indigoAccent,
                    title: 'Thông tin cá nhân',
                    // Hiển thị trực tiếp Họ tên người dùng lấy từ Entity sạch
                    trailingText: currentUser?.fullName ?? 'Chưa cập nhật',
                    onTap: () {
                      context.push(RoutePaths.editProfile);
                    },
                  ),
                  Divider(color: colors.textSecondary.withOpacity(0.1), height: 1, indent: 16, endIndent: 16),
                  ProfileMenuItem(
                    icon: Icons.fingerprint_rounded,
                    iconColor: Colors.purpleAccent,
                    title: 'Bảo mật & Sinh trắc học',
                    onTap: () {},
                  ),
                  Divider(color: colors.textSecondary.withOpacity(0.1), height: 1, indent: 16, endIndent: 16),
                  ProfileMenuItem(
                    icon: Icons.notifications_none_rounded,
                    iconColor: Colors.blue,
                    title: 'Cài đặt thông báo',
                    onTap: () {},
                  ),
                  Divider(color: colors.textSecondary.withOpacity(0.1), height: 1, indent: 16, endIndent: 16),
                  ProfileMenuItem(
                    icon: Icons.palette_outlined,
                    iconColor: Colors.amber,
                    title: 'Giao diện người dùng',
                    trailingText: currentUser?.theme == 'dark' ? 'Tối' : 'Sáng',
                    onTap: () {},
                  ),
                  Divider(color: colors.textSecondary.withOpacity(0.1), height: 1, indent: 16, endIndent: 16),
                  ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: Colors.teal,
                    title: 'Trợ giúp & Hỗ trợ',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- NÚT ĐĂNG XUẤT ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: Icon(Icons.logout_rounded, color: colors.expenseRed),
                label: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: colors.expenseRed,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.textSecondary.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: colors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}