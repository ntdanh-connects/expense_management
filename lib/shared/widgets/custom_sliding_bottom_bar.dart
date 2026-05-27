import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'bottom_bar_config.dart';
import 'quick_action_button.dart';

class CustomSlidingBottomBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomSlidingBottomBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = BottomBarConfig.mainTabs;

    final authState = ref.watch(authNotifierProvider);
    Color dynamicColor = color.primary;
    authState.maybeWhen(authenticated: (u) { final hex = u.theme.replaceAll('#', ''); if (hex.length == 6) dynamicColor = Color(int.parse('FF$hex', radix: 16)); }, orElse: () {});

    // Toán tử nhảy cóc qua ô số 2 của nút dấu (+) chính giữa
    int slidingIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 5),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: isDark ? color.authCardBg.withOpacity(0.9) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.textSecondary.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.08), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / 5; // Chia 5 ô đối xứng tuyệt đối

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                curve: Curves.fastOutSlowIn, duration: const Duration(milliseconds: 300),
                left: slidingIndex * itemWidth + 6, top: 8,
                child: Container(width: itemWidth - 12, height: 52, decoration: BoxDecoration(color: dynamicColor.withOpacity(0.15), borderRadius: BorderRadius.circular(18), border: Border.all(color: dynamicColor.withOpacity(0.3)))),
              ),
              // 🔮 2. THANH CHỨA HÀNG NÚT ĐỐI XỨNG QUAY QUANH NÚT TRUNG TÂM
              Row(
                children: [
                  _buildTab(context, tabs[0], 0, itemWidth, dynamicColor, color),
                  _buildTab(context, tabs[1], 1, itemWidth, dynamicColor, color),
                  _buildPlusButton(context, itemWidth, dynamicColor),
                  _buildTab(context, tabs[2], 2, itemWidth, dynamicColor, color),
                  _buildTab(context, tabs[3], 3, itemWidth, dynamicColor, color),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  // Widget vẽ nút (+) phát sáng Neon
  Widget _buildPlusButton(BuildContext context, double width, Color neonColor) {
    return SizedBox(
      width: width, height: 68,
      child: Center(
        child: InkWell(
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => QuickActionBottomSheet(systemAccentColor: neonColor)),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: neonColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: neonColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Icon(Icons.add_rounded, color: neonColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  // Widget vẽ các nút Tab chức năng mộc mạc
  Widget _buildTab(BuildContext context, BottomBarItem item, int idx, double width, Color actColor, dynamic color) {
    final isSel = idx == currentIndex;
    final displayColor = isSel ? actColor : color.textSecondary;
    return SizedBox(
      width: width, height: 68,
      child: InkWell(
        onTap: () => onTap(idx), splashColor: Colors.transparent, highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: displayColor, size: isSel ? 24 : 22),
            const SizedBox(height: 4),
            Text(item.label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: displayColor)),
          ],
        ),
      ),
    );
  }
}