import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'profile_menu_item.dart';

class FinancialSettingsSection extends StatelessWidget {
  const FinancialSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; //[cite: 22]

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THIẾT LẬP TÀI CHÍNH',
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
                icon: Icons.category_outlined,
                iconColor: colors.profileCategory,
                title: 'Quản lý danh mục',
                onTap: () {},
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.calendar_month_outlined,
                iconColor: colors.profileCalendar,
                title: 'Tháng tài chính',
                onTap: () {},
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: colors.profileLimit,
                title: 'Hạn mức chi tiêu',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}