import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
class CustomSlidingBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const CustomSlidingBottomBar({super.key,required this.currentIndex,required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<BottomBarItem> items = [
      BottomBarItem(icon: Icons.grid_view_rounded, label: 'Tổng quan'),
      BottomBarItem(icon: Icons.account_balance_wallet_rounded, label: 'Ví tiền'),
      BottomBarItem(icon: Icons.analytics_outlined, label: 'Thống kê'),
      BottomBarItem(icon: Icons.person_outline_rounded, label: 'Cá nhân'),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 5,
      ),
      child: Container(
        height: 68,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? color.authCardBg.withOpacity(0.9) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.textSecondary.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double containerWidth = constraints.maxWidth;
            final double itemWidth = containerWidth / items.length;

            return Stack(
              children: [
                AnimatedPositioned(
                  curve: Curves.fastOutSlowIn,
                  left: currentIndex * itemWidth + 6,
                  top: 8,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: itemWidth - 12,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.primary.withOpacity(0.3), width: 1),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    return SizedBox(
                      width: itemWidth,
                      height: 68,
                      child: InkWell(
                        onTap: () => onTap(index),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                item.icon,
                                color: isSelected ? color.primary : color.textSecondary,
                                size: isSelected ? 24 : 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? color.primary : color.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BottomBarItem{
  final IconData icon;
  final String label;
  BottomBarItem({
    required this.icon,
    required this.label
  });
}