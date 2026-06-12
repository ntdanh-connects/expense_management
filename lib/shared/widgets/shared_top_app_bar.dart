import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/modern_em_logo.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/notification/presentation/widgets/notification_sidebar.dart';

class SharedTopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearchChanged;
  final String hintText;
  
  const SharedTopAppBar({
    super.key,
    this.onSearchChanged,
    this.hintText = 'Tìm kiếm giao dịch, ví, hũ...',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final primaryColor = colors.primary;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: primaryColor, // Nền màu chủ đạo xanh/tím của hệ thống
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              // 👤 1. LOGO TRÒN CÓ VIỀN
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const ModernEMLogo(size: 34, showShadow: false),
              ),
              const SizedBox(width: 12),

              // 🔍 2. THANH TÌM KIẾM BO TRÒN KÍNH MỜ (GLASSMORPHISM)
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 🤖 3. NÚT AI / SPARKLES
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),

              // 🔔 4. NÚT NOTIFICATION CÓ BADGE SỐ
              GestureDetector(
                onTap: () => NotificationSidebar.show(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(54);
}
