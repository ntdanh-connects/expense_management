import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart'; // Nạp extension màu sắc của anh em mình

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final bool enabled;
  final IconData? suffixIcon;
  final VoidCallback? onPressSuffixIcon;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.onPressSuffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final currentColors = context.colors;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      
      style: TextStyle(color: currentColors.textPrimary, fontSize: 15),
      cursorColor: currentColors.primary,
      
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: currentColors.textSecondary.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: currentColors.textPrimary, size: 22),
        suffixIcon: suffixIcon != null ? IconButton(onPressed: 
          onPressSuffixIcon
        , icon: Icon(suffixIcon,color: currentColors.textPrimary,size: 22,)): null,
        filled: true,
        fillColor: isDark 
            ? currentColors.background.withOpacity(0.5) 
            : currentColors.surface, 
        
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: currentColors.textSecondary.withOpacity(isDark ? 0.1 : 0.15),
          ),
        ),
        
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: currentColors.primary, width: 1.5),
        ),
        
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