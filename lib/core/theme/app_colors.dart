import 'package:flutter/material.dart';

extension AppThemeExpenseManagement on BuildContext{
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color incomeGreen;
  final Color expenseRed;

  AppColorsExtension({
    required this.background,
    required this.surface,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.incomeGreen,
    required this.expenseRed,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
    Color? incomeGreen,
    Color? expenseRed,
  }){
   return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      incomeGreen: incomeGreen ?? this.incomeGreen,
      expenseRed: expenseRed ?? this.expenseRed,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      incomeGreen: Color.lerp(incomeGreen, other.incomeGreen, t)!,
      expenseRed: Color.lerp(expenseRed, other.expenseRed, t)!,
    );
  }

  static final light = AppColorsExtension(
    background: const Color(0xFFF4F6FA),   
    surface: Colors.white,                 
    primary: const Color(0xFF52B788),      
    textPrimary: const Color(0xFF0F172A),  
    textSecondary: const Color(0xFF64748B),
    incomeGreen: const Color(0xFF10B981),  
    expenseRed: const Color(0xFFEF4444),   
  );

  static final dark = AppColorsExtension(
    background: const Color(0xFF111827),   
    surface: const Color(0xFF1F2937),      
    primary: const Color(0xFF74C69D),      
    textPrimary: Colors.white,             
    textSecondary: const Color(0xFF9CA3AF),
    incomeGreen: const Color(0xFF34D399),  
    expenseRed: const Color(0xFFF87171),   
  );
}