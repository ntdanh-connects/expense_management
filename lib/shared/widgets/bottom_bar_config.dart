import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:go_router/go_router.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  BottomBarItem({required this.icon, required this.label});
}

class QuickActionConfig {
  final IconData icon;
  final String title;
  final Color? customColor;
  final String? badgeText;
  final VoidCallback? onTap;

  QuickActionConfig({
    required this.icon,
    required this.title,
    this.customColor,
    this.badgeText,
    this.onTap,
  });
}

class BottomBarConfig {
  // 1. Khai báo 4 Tab chức năng chính tương ứng 4 Branch GoRouter
  static final List<BottomBarItem> mainTabs = [
    BottomBarItem(icon: Icons.grid_view_rounded, label: 'Tổng quan'),
    BottomBarItem(icon: Icons.receipt_long_rounded, label: 'Lịch sử'),
    BottomBarItem(icon: Icons.analytics_outlined, label: 'Thống kê'),
    BottomBarItem(icon: Icons.person_outline_rounded, label: 'Cá nhân'),
  ];

  // 2. 🤖 KHO CHỨA TÍNH NĂNG AI KHI BẤM NÚT DẤU (+): MỐT SCALE CHỈ CẦN THÊM DÒNG Ở ĐÂY!
  static List<QuickActionConfig> getQuickActions(BuildContext context, Color systemAccentColor, WidgetRef ref) {
    return [
      QuickActionConfig(
        icon: Icons.edit_note_rounded,
        title: 'manual_input'.tr(ref),
        customColor: systemAccentColor,
        onTap: () {
          context.push('/add-transaction');
        },
      ),
      QuickActionConfig(
        icon: Icons.auto_awesome_rounded,
        title: 'smart_scan'.tr(ref),
        customColor: const Color(0xFFFF00FF), // Màu Magenta của AI
        badgeText: '🤖 AI',
      ),
    ];
  }
}