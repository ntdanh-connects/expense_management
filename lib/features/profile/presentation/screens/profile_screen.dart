import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:expense_management/features/security/presentation/providers/security_provider.dart';
import 'package:flutter/services.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/core/utils/log_console_screen.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
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
                'delete_account_q'.tr(ref),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'delete_account_desc'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr(ref), style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Text('deleting_account_progress'.tr(ref)),
                      ],
                    ),
                    duration: const Duration(days: 1),
                  ),
                );

                try {
                  await ref.read(userRepositoryProvider).deleteAccount();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('delete_account_success'.tr(ref)),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  onLogout();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${'error'.tr(ref)}: ${e.toString().replaceFirst('Exception: ', '')}'),
                      backgroundColor: colors.expenseRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.expenseRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('confirm_delete'.tr(ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDisablePinConfirmDialog(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pinController = TextEditingController();
    String error = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'confirm_disable_pin_title'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('confirm_disable_pin_desc'.tr(ref)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textPrimary, fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primary)),
                    ),
                    onChanged: (val) async {
                      if (val.length == 4) {
                        final correct = await ref.read(securityNotifierProvider.notifier).verifyPin(val);
                        if (correct) {
                          await ref.read(securityNotifierProvider.notifier).disablePin();
                          if (ctx.mounted) Navigator.pop(ctx);
                        } else {
                          HapticFeedback.vibrate();
                          setDialogState(() {
                            pinController.clear();
                            error = 'pin_incorrect_try_again'.tr(ref);
                          });
                        }
                      }
                    },
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(error, style: TextStyle(color: colors.expenseRed, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: Text('cancel'.tr(ref), style: TextStyle(color: colors.textSecondary)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            onTap: () => context.push(RoutePaths.editProfile), // Điều hướng sang màn hình thông tin
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
                    (() {
                      final securityState = ref.watch(securityNotifierProvider);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'security_title'.tr(ref).toUpperCase(),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: colors.authCardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                // Switch Bật/Tắt PIN Lock
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_outline_rounded, color: colors.profileSecurity, size: 22),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'lock_app_pin'.tr(ref),
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: securityState.isPinEnabled,
                                        activeColor: colors.primary,
                                        onChanged: (value) async {
                                          if (value) {
                                            await context.push(RoutePaths.pinSetup);
                                          } else {
                                            // Tắt tính năng -> yêu cầu xác thực PIN hiện tại
                                            _showDisablePinConfirmDialog(context, ref);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (securityState.isPinEnabled) ...[
                                  Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                                  // Đổi mã PIN
                                  ProfileMenuItem(
                                    icon: Icons.pin_rounded,
                                    iconColor: colors.profileSecurity,
                                    title: 'change_pin'.tr(ref),
                                    onTap: () {
                                      context.push(RoutePaths.pinSetup);
                                    },
                                  ),
                                  Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                                  // Switch Bật/Tắt Face ID
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.fingerprint_rounded, color: colors.profileSecurity, size: 22),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'unlock_with_biometric'.tr(ref),
                                            style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: securityState.isBiometricEnabled,
                                          activeColor: colors.primary,
                                          onChanged: (val) async {
                                            await ref.read(securityNotifierProvider.notifier).setBiometricEnabled(val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    })(),

                    const FinancialSettingsSection(),

                    const SizedBox(height: 20),
                    Text(
                      'theme'.tr(ref).toUpperCase(),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.palette_outlined, color: colors.profileTheme, size: 22),
                                    const SizedBox(width: 16),
                                    Text(
                                      'theme'.tr(ref),
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
                                      _buildThemeTab(context, ref, 'dark_mode'.tr(ref), true, isDark),
                                      _buildThemeTab(context, ref, 'light_mode'.tr(ref), false, !isDark),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showLanguageBottomSheet(context, ref),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.translate_rounded, color: colors.profileNotification, size: 22),
                                        const SizedBox(width: 16),
                                        Text(
                                          'language'.tr(ref),
                                          style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          ref.watch(localeProvider) == 'vi' ? 'vietnamese'.tr(ref) : 'english'.tr(ref),
                                          style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary.withOpacity(0.5), size: 14),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- HỖ TRỢ (Hình 1) ---
                    Text(
                      'support'.tr(ref).toUpperCase(),
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
                            title: 'help_support'.tr(ref),
                            onTap: () {},
                          ),
                          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                          ProfileMenuItem(
                            icon: Icons.delete_outline_rounded,
                            iconColor: colors.expenseRed,
                            title: 'delete_account'.tr(ref),
                            onTap: () => _showDeleteAccountDialog(context, ref),
                          ),
                        ],
                      ),
                    ),

                    if (showDevTools) ...[
                      const SizedBox(height: 20),

                      // --- CÔNG CỤ PHÁT TRIỂN ---
                      Text(
                        'dev_tools'.tr(ref).toUpperCase(),
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
                              title: 'dev_console'.tr(ref),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LogConsoleScreen()),
                                );
                              },
                            ),
                            Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                            ProfileMenuItem(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: colors.primary,
                              title: 'Giả lập Sandbox',
                              onTap: () {
                                context.push(RoutePaths.sandboxSimulateTransfer);
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
                                              'show_floating_bubble'.tr(ref),
                                              style: TextStyle(
                                                color: colors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'dev_console_desc'.tr(ref),
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

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'language'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                context,
                ref,
                title: 'vietnamese'.tr(ref),
                localeCode: 'vi',
                isSelected: currentLocale == 'vi',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                ref,
                title: 'english'.tr(ref),
                localeCode: 'en',
                isSelected: currentLocale == 'en',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String localeCode,
    required bool isSelected,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        
        // 1. Cập nhật app language ở local
        await ref.read(appLanguageProvider.notifier).changeLocale(localeCode);
        
        // 2. Đồng bộ lên backend thông qua profile update
        try {
          await ref.read(updateProfileUseCaseProvider).execute(language: localeCode);
          // 3. Làm mới danh mục để cập nhật ngôn ngữ tương ứng
          await ref.read(categoriesNotifierProvider.notifier).refreshCategories();
        } catch (e) {
          // Bỏ qua lỗi mạng vì local đã cập nhật mượt mà
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.textSecondary.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 22)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.textSecondary.withOpacity(0.3),
                    width: 1.5,
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