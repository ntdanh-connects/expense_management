import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/core/utils/log_console_screen.dart';
import 'profile_menu_item.dart';

class ProfileDevToolsSection extends ConsumerWidget {
  const ProfileDevToolsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
