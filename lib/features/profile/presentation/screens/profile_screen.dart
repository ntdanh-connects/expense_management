import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';

import '../widgets/profile/profile_menu_item.dart';
import '../widgets/profile/profile_header_card.dart';
import '../widgets/profile/collapsible_budget_card.dart';
import '../widgets/profile/financial_settings_section.dart';
import '../widgets/profile/profile_theme_selector.dart';
import '../widgets/profile/profile_language_selector.dart';
import '../widgets/profile/profile_security_section.dart';
import '../widgets/profile/profile_support_section.dart';
import '../widgets/profile/profile_dev_tools_section.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final showDevTools = ref.watch(developerToolsEnabledProvider);
    final currentBudgetsAsync = ref.watch(currentMonthBudgetsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 370.0,
              floating: false,
              pinned: true,
              backgroundColor: colors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    ProfileHeaderCard(
                      fullName: currentUser?.fullName ?? 'unnamed_user'.tr(ref),
                      membershipTier: 'platinum_member'.tr(ref),
                      avatarUrl: currentUser?.avatarUrl,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: currentBudgetsAsync.when(
                        data: (budgets) {
                          final general = budgets.where((b) => b.categoryId == null).firstOrNull;
                          if (general == null) {
                            return const CollapsibleBudgetCard(
                              spentAmount: 0.0,
                              totalAmount: 0.0,
                            );
                          }
                          return CollapsibleBudgetCard(
                            spentAmount: general.usedAmount,
                            totalAmount: general.limitAmount,
                          );
                        },
                        loading: () => const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => const CollapsibleBudgetCard(
                          spentAmount: 0.0,
                          totalAmount: 0.0,
                        ),
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
                      'settings'.tr(ref).toUpperCase(),
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
                            title: 'personal_info'.tr(ref),
                            onTap: () => context.push(RoutePaths.editProfile),
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          ProfileMenuItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: colors.profileNotification,
                            title: 'notification_settings'.tr(ref),
                            onTap: () => context.push('/profile/notifications'),
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          ProfileMenuItem(
                            icon: Icons.lock_reset_outlined,
                            iconColor: colors.profileNotification,
                            title: 'change_password'.tr(ref),
                            onTap: () => context.push(RoutePaths.changePassword),
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          ProfileMenuItem(
                            icon: Icons.devices_other_rounded,
                            iconColor: colors.profileSecurity,
                            title: 'device_sessions_management'.tr(ref),
                            onTap: () => context.push(RoutePaths.activeSessions),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- BẢO MẬT (Khóa PIN / Face ID) ---
                    const ProfileSecuritySection(),

                    const SizedBox(height: 20),

                    // --- THIẾT LẬP TÀI CHÍNH ---
                    const FinancialSettingsSection(),

                    const SizedBox(height: 20),

                    // --- THEME & NGÔN NGỮ ---
                    const ProfileThemeSelector(),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.authCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const ProfileLanguageSelector(),
                    ),

                    const SizedBox(height: 20),

                    // --- HỖ TRỢ & XÓA TÀI KHOẢN ---
                    ProfileSupportSection(onLogout: onLogout),

                    if (showDevTools) ...[
                      const SizedBox(height: 20),
                      const ProfileDevToolsSection(),
                    ],

                    const SizedBox(height: 32),

                    // --- NÚT ĐĂNG XUẤT ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: onLogout,
                        icon: Icon(Icons.logout_rounded, color: colors.expenseRed),
                        label: Text('logout'.tr(ref), style: TextStyle(color: colors.expenseRed, fontSize: 16, fontWeight: FontWeight.bold)),
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
}