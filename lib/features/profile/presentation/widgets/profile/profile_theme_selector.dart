import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:expense_management/core/language/app_language.dart';

class ProfileThemeSelector extends ConsumerWidget {
  const ProfileThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: Padding(
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
        ),
      ],
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
