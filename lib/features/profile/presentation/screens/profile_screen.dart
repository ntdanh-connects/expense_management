import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/core/utils/log_console_screen.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/collapsible_budget_card.dart';
import '../widgets/financial_settings_section.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colors.authCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.expenseRed, size: 28),
              const SizedBox(width: 10),
              Text(
                'Xóa tài khoản?',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Hành động này không thể hoàn tác. Toàn bộ dữ liệu ví, giao dịch và thông tin cá nhân của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống Laravel.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Hủy', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Đang tiến hành xóa tài khoản của bạn...'),
                      ],
                    ),
                    duration: Duration(days: 1),
                  ),
                );

                try {
                  await ref.read(userRepositoryProvider).deleteAccount();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Tài khoản đã được xóa vĩnh viễn.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  onLogout();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
                      backgroundColor: colors.expenseRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.expenseRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showDevTools = ref.watch(developerToolsEnabledProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 345.0,
              floating: false,
              pinned: true,
              backgroundColor: colors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    ProfileHeaderCard(
                      fullName: currentUser?.fullName ?? 'Người dùng chưa có tên',
                      membershipTier: 'Hội viên Bạch Kim',
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CollapsibleBudgetCard(
                        spentAmount: 12500000,
                        totalAmount: 15000000,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÀI ĐẶT TÀI KHOẢN',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.authCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ProfileMenuItem(
                            icon: Icons.person_outline_rounded,
                            iconColor: colors.profileInfo,
                            title: 'Thông tin cá nhân',
                            onTap: () => context.push(RoutePaths.editProfile),
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          ProfileMenuItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: colors.profileNotification,
                            title: 'Cài đặt thông báo',
                            onTap: () => context.push('/profile/notifications'),
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          ProfileMenuItem(
                            icon: Icons.lock_reset_outlined,
                            iconColor: colors.profileNotification,
                            title: 'Đổi mật khẩu',
                            onTap: () => context.push(RoutePaths.changePassword),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const FinancialSettingsSection(),

                    const SizedBox(height: 20),
                    Text(
                      'GIAO DIỆN NGƯỜI DÙNG',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.authCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_outlined, color: colors.profileTheme, size: 22),
                              const SizedBox(width: 16),
                              Text(
                                'Chế độ hiển thị',
                                style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          // Widget Toggle Theme đơn giản hoặc Custom Switch đồng bộ Hình 1
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                _buildThemeTab(context, ref, 'Tối', true, isDark),
                                _buildThemeTab(context, ref, 'Sáng', false, !isDark),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- HỖ TRỢ (Hình 1) ---
                    Text(
                      'HỖ TRỢ',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.authCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ProfileMenuItem(
                            icon: Icons.help_outline_rounded,
                            iconColor: colors.profileHelp,
                            title: 'Trợ giúp & Hỗ trợ',
                            onTap: () {},
                          ),
                          Divider(height: 1, thickness: 1, color: colors.textSecondary.withOpacity(0.05)),
                          ProfileMenuItem(
                            icon: Icons.delete_forever_rounded,
                            title: 'Xóa tài khẩu',
                            iconColor: colors.expenseRed,
                            onTap: () => _showDeleteAccountDialog(context, ref),
                          ),
                        ],
                      ),
                    ),

                    if (showDevTools) ...[
                      const SizedBox(height: 20),

                      // --- CÔNG CỤ PHÁT TRIỂN ---
                      Text(
                        'CÔNG CỤ PHÁT TRIỂN (DEV)',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.authCardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            ProfileMenuItem(
                              icon: Icons.terminal_rounded,
                              iconColor: colors.profileInfo,
                              title: 'Trình xem Log Lỗi & Mạng (Console)',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LogConsoleScreen()),
                                );
                              },
                            ),
                            Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                            ValueListenableBuilder<bool>(
                              valueListenable: AppLogger.isConsoleOverlayVisible,
                              builder: (context, isVisible, _) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.bug_report_rounded, color: colors.profileTheme, size: 22),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hiển thị nút bong bóng nổi (Floating)',
                                              style: TextStyle(
                                                color: colors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Hỗ trợ truy cập nhanh Dev Console',
                                              style: TextStyle(
                                                color: colors.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: isVisible,
                                        activeColor: colors.primary,
                                        onChanged: (value) async {
                                          AppLogger.isConsoleOverlayVisible.value = value;
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setBool('show_developer_console', value);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // --- NÚT ĐĂNG XUẤT ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: onLogout,
                        icon: Icon(Icons.logout_rounded, color: colors.expenseRed),
                        label: Text('Đăng xuất', style: TextStyle(color: colors.expenseRed, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.textSecondary.withOpacity(0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: colors.authCardBg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTab(BuildContext context, WidgetRef ref, String label, bool isDarkTarget, bool isActive) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          ref.read(themeProvider.notifier).toggleTheme();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}