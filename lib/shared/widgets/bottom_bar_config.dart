import 'package:flutter/material.dart';

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
    BottomBarItem(icon: Icons.account_balance_wallet_rounded, label: 'Ví tiền'),
    BottomBarItem(icon: Icons.analytics_outlined, label: 'Thống kê'),
    BottomBarItem(icon: Icons.person_outline_rounded, label: 'Cá nhân'),
  ];

  // 2. 🤖 KHO CHỨA TÍNH NĂNG AI KHI BẤM NÚT DẤU (+): MỐT SCALE CHỈ CẦN THÊM DÒNG Ở ĐÂY!
  static List<QuickActionConfig> getQuickActions(BuildContext context, Color systemAccentColor) {
    return [
      QuickActionConfig(
        icon: Icons.edit_note_rounded,
        title: 'Nhập bằng tay thủ công',
        customColor: systemAccentColor,
      ),
      QuickActionConfig(
        icon: Icons.auto_awesome_rounded,
        title: 'Quét hóa đơn thông minh (AI)',
        customColor: const Color(0xFFFF00FF), // Màu Magenta của AI
        badgeText: '🤖 AI',
      ),
    ];
  }
}