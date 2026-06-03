import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/modern_em_logo.dart';

class SharedTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearchChanged;
  final String hintText;
  
  const SharedTopAppBar({
    super.key,
    this.onSearchChanged,
    this.hintText = 'Tìm kiếm giao dịch, ví, hũ...',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.primary;

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

              // 🔔 4. NÚT NOTIFICATION CÓ BADGE ĐỎ BÁO HIỆU
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
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
                  )
                ],
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
