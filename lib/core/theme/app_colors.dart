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
  final Color authCardBg;
  final Gradient authGradient;

  // Profile-specific colors
  final Color profileInfo;
  final Color profileSecurity;
  final Color profileNotification;
  final Color profileTheme;
  final Color profileHelp;
  final Color profileCategory;
  final Color profileCalendar;
  final Color profileLimit;
  final Color profileBudgetProgress;
  final Gradient profileHeaderGradient;

  AppColorsExtension({
    required this.background,
    required this.surface,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.incomeGreen,
    required this.expenseRed,
    required this.authCardBg,
    required this.authGradient,
    required this.profileInfo,
    required this.profileSecurity,
    required this.profileNotification,
    required this.profileTheme,
    required this.profileHelp,
    required this.profileCategory,
    required this.profileCalendar,
    required this.profileLimit,
    required this.profileBudgetProgress,
    required this.profileHeaderGradient,
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
    Color? authCardBg,
    Gradient? authGradient,
    Color? profileInfo,
    Color? profileSecurity,
    Color? profileNotification,
    Color? profileTheme,
    Color? profileHelp,
    Color? profileCategory,
    Color? profileCalendar,
    Color? profileLimit,
    Color? profileBudgetProgress,
    Gradient? profileHeaderGradient,
  }){
   return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      incomeGreen: incomeGreen ?? this.incomeGreen,
      expenseRed: expenseRed ?? this.expenseRed,
      authCardBg: authCardBg ?? this.authCardBg,
      authGradient: authGradient ?? this.authGradient,
      profileInfo: profileInfo ?? this.profileInfo,
      profileSecurity: profileSecurity ?? this.profileSecurity,
      profileNotification: profileNotification ?? this.profileNotification,
      profileTheme: profileTheme ?? this.profileTheme,
      profileHelp: profileHelp ?? this.profileHelp,
      profileCategory: profileCategory ?? this.profileCategory,
      profileCalendar: profileCalendar ?? this.profileCalendar,
      profileLimit: profileLimit ?? this.profileLimit,
      profileBudgetProgress: profileBudgetProgress ?? this.profileBudgetProgress,
      profileHeaderGradient: profileHeaderGradient ?? this.profileHeaderGradient,
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
      authCardBg: Color.lerp(authCardBg, other.authCardBg, t)!,
      authGradient: Gradient.lerp(authGradient, other.authGradient, t)!,
      profileInfo: Color.lerp(profileInfo, other.profileInfo, t)!,
      profileSecurity: Color.lerp(profileSecurity, other.profileSecurity, t)!,
      profileNotification: Color.lerp(profileNotification, other.profileNotification, t)!,
      profileTheme: Color.lerp(profileTheme, other.profileTheme, t)!,
      profileHelp: Color.lerp(profileHelp, other.profileHelp, t)!,
      profileCategory: Color.lerp(profileCategory, other.profileCategory, t)!,
      profileCalendar: Color.lerp(profileCalendar, other.profileCalendar, t)!,
      profileLimit: Color.lerp(profileLimit, other.profileLimit, t)!,
      profileBudgetProgress: Color.lerp(profileBudgetProgress, other.profileBudgetProgress, t)!,
      profileHeaderGradient: Gradient.lerp(profileHeaderGradient, other.profileHeaderGradient, t)!,
    );
  }

  static final light = AppColorsExtension(
    background: const Color(0xFFF8F9FA),   
    surface: Colors.white,                 
    primary: const Color(0xFF4F46E5),      
    textPrimary: const Color(0xFF0F172A),  
    textSecondary: const Color(0xFF64748B),
    incomeGreen: const Color(0xFF10B981),  
    expenseRed: const Color(0xFFEF4444),   
    authCardBg: Colors.white,
    authGradient: const LinearGradient(
      colors: [Color(0xFFF8F9FA), Colors.white],
    ),
    profileInfo: const Color(0xFF3B82F6),
    profileSecurity: const Color(0xFF10B981),
    profileNotification: const Color(0xFFF59E0B),
    profileTheme: const Color(0xFF8B5CF6),
    profileHelp: const Color(0xFF14B8A6),
    profileCategory: const Color(0xFF6366F1),
    profileCalendar: const Color(0xFF4F46E5),
    profileLimit: const Color(0xFF2563EB),
    profileBudgetProgress: const Color(0xFFF59E0B),
    profileHeaderGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
    ),
  );

  static final dark = AppColorsExtension(
    background: const Color(0xFF0B0D17),   
    surface: const Color(0xFF1F2937),      
    primary: const Color(0xFF4F46E5),      
    textPrimary: Colors.white,             
    textSecondary: const Color(0xFF9CA3AF),
    incomeGreen: const Color(0xFF34D399),  
    expenseRed: const Color(0xFFF87171),  
    authCardBg: const Color(0xFF111318),
    authGradient: const LinearGradient(   
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0B0D17),
        Color(0xFF1A103C),
        Color(0xFF2D0B3D),
      ],
    ),
    profileInfo: const Color(0xFF60A5FA),
    profileSecurity: const Color(0xFF34D399),
    profileNotification: const Color(0xFFFBBF24),
    profileTheme: const Color(0xFFA78BFA),
    profileHelp: const Color(0xFF2DD4BF),
    profileCategory: const Color(0xFF818CF8),
    profileCalendar: const Color(0xFF6366F1),
    profileLimit: const Color(0xFF60A5FA),
    profileBudgetProgress: const Color(0xFFFBBF24),
    profileHeaderGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
    ),
  );
}