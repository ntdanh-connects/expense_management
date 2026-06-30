import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class CategoryManagementTabSwitcher extends ConsumerWidget {
  final int activeTabIndex;
  final TabController tabController;
  final ValueChanged<int> onTabChanged;

  const CategoryManagementTabSwitcher({
    super.key,
    required this.activeTabIndex,
    required this.tabController,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.textSecondary.withOpacity(0.1), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            context,
            ref,
            index: 0,
            label: 'expense_label'.tr(ref),
            icon: Icons.trending_down_rounded,
            activeColor: colors.profileInfo,
          ),
          _buildTabItem(
            context,
            ref,
            index: 1,
            label: 'income_label'.tr(ref),
            icon: Icons.trending_up_rounded,
            activeColor: colors.incomeGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final colors = context.colors;
    final isActive = activeTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTabChanged(index);
          tabController.animateTo(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? activeColor : colors.textSecondary.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? activeColor : colors.textSecondary.withOpacity(0.7),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
