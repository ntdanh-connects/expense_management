import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart'; // Nạp extension màu sắc của anh em mình

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 CHÌA KHÓA VÀNG: Lấy màu động từ context.colors!
    // Trình biên dịch tự động dò xem app đang bật chế độ Sáng hay Tối để nhả màu tương ứng.
    final currentColors = context.colors;
    
    // Check ngầm xem hệ thống hiện tại có phải đang là Dark Theme hay không
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      
      // 🌟 TỰ ĐỘNG BIẾN HÌNH MÀU CHỮ: Tối thì chữ trắng, Sáng thì chữ đen Slate 900
      style: TextStyle(color: currentColors.textPrimary, fontSize: 15),
      cursorColor: currentColors.primary, // Con trỏ nhấp nháy theo màu chủ đạo của từng Theme
      
      decoration: InputDecoration(
        hintText: hintText,
        // Chữ gợi ý mờ dịu mắt theo từng môi trường
        hintStyle: TextStyle(color: currentColors.textSecondary.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: currentColors.textPrimary, size: 22),
        suffixIcon: suffixIcon,
        
        filled: true,
        // ⚡ TỰ ĐỘNG BIẾN HÌNH MÀU NỀN HỘP NHẬP:
        // Nếu là Dark Theme: Hộp màu đen mờ của BankDash (background.withOpacity(0.5))
        // Nếu là Light Theme: Hộp màu trắng tinh khôi sạch sẽ của SpendWise (Colors.white)
        fillColor: isDark 
            ? currentColors.background.withOpacity(0.5) 
            : currentColors.surface, 
        
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        
        // Viền lúc bình thường: Tự động ăn theo màu textSecondary mờ của từng hệ theme tương ứng
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: currentColors.textSecondary.withOpacity(isDark ? 0.1 : 0.15),
          ),
        ),
        
        // Viền lúc chạm gõ chữ: Nổ khung màu chủ đạo rực rỡ (Light nổ Tím Indigo, Dark nổ Xanh Dương Neon)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: currentColors.primary, width: 1.5),
        ),
        
        // Viền lúc dính bẫy Validator báo lỗi đỏ
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: currentColors.expenseRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: currentColors.expenseRed, width: 1.5),
        ),
        
        errorStyle: TextStyle(color: currentColors.expenseRed, fontWeight: FontWeight.w500),
      ),
    );
  }
}