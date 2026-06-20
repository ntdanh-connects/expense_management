import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/security/presentation/providers/security_provider.dart';
import 'package:expense_management/core/language/app_language.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _currentInput = '';
  String _errorMessage = '';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Tự động gọi xác thực Face ID/Vân tay sau khi màn hình được dựng xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometrics();
    });
  }

  Future<void> _triggerBiometrics() async {
    final securityState = ref.read(securityNotifierProvider);
    if (securityState.isBiometricEnabled) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await ref.read(securityNotifierProvider.notifier).authenticateWithBiometrics();
      }
    }
  }

  void _onNumberPress(String number) {
    if (_isChecking || _currentInput.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentInput += number;
      _errorMessage = '';
    });

    if (_currentInput.length == 4) {
      _verifyPinInput();
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty || _isChecking) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _errorMessage = '';
    });
  }

  Future<void> _verifyPinInput() async {
    setState(() {
      _isChecking = true;
    });

    // Tạo độ trễ nhỏ để người dùng thấy ô thứ 4 sáng lên
    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    final isCorrect = await ref.read(securityNotifierProvider.notifier).verifyPin(_currentInput);

    if (isCorrect) {
      // Mở khóa thành công -> unlock() đã được gọi trong verifyPin
      setState(() {
        _currentInput = '';
        _isChecking = false;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _currentInput = '';
        _isChecking = false;
        _errorMessage = 'pin_incorrect_try_again'.trRead(ref);
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'logout_confirm_title'.trRead(ref),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'forgot_pin_logout_desc'.trRead(ref),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.trRead(ref), style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Xóa cấu hình bảo mật cục bộ
                await ref.read(securityNotifierProvider.notifier).clearSecurityData();
                // Thực hiện Logout tài khoản
                await ref.read(authNotifierProvider.notifier).logout();
              },
              child: Text('logout'.trRead(ref), style: TextStyle(color: colors.expenseRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final securityState = ref.watch(securityNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sử dụng authGradient cho nền đồng bộ
    final backgroundGradient = isDark 
        ? colors.authGradient 
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.background, colors.background],
          );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0D17) : colors.background,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield Lock Icon
              Icon(
                Icons.lock_outline_rounded,
                size: 68,
                color: colors.primary,
              ),
              const SizedBox(height: 24),

              // Title hướng dẫn
              Text(
                'enter_pin_to_unlock'.tr(ref),
                style: TextStyle(
                  color: isDark ? Colors.white : colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // 4 ô tròn biểu thị PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final hasValue = index < _currentInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasValue 
                          ? colors.primary 
                          : (isDark ? Colors.white24 : Colors.grey[300]),
                      border: Border.all(
                        color: hasValue ? colors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              
              // Thông báo lỗi nếu có
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: colors.expenseRed, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(flex: 3),

              // Bàn phím số numeric keypad (như mockup hình ảnh)
              _buildKeyboard(securityState, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(SecurityState securityState, bool isDark) {
    final colors = context.colors;
    final buttonTextColor = isDark ? Colors.white : colors.textPrimary;
    final buttonBgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((n) => _buildKeyboardButton(n, buttonTextColor, buttonBgColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((n) => _buildKeyboardButton(n, buttonTextColor, buttonBgColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((n) => _buildKeyboardButton(n, buttonTextColor, buttonBgColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Nút "Đăng xuất" ở góc trái dưới cùng
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 75,
                height: 75,
                alignment: Alignment.center,
                child: Text(
                  'logout'.tr(ref),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.expenseRed.withOpacity(0.9),
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            _buildKeyboardButton('0', buttonTextColor, buttonBgColor),
            
            // Nút Sinh trắc học hoặc Xóa bên phải
            if (_currentInput.isNotEmpty)
              InkWell(
                onTap: _onBackspace,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 75,
                  height: 75,
                  alignment: Alignment.center,
                  child: Icon(Icons.backspace_outlined, color: buttonTextColor, size: 24),
                ),
              )
            else if (securityState.isBiometricEnabled)
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(securityNotifierProvider.notifier).authenticateWithBiometrics();
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 75,
                  height: 75,
                  alignment: Alignment.center,
                  child: Platform.isIOS
                      ? SFIcon(
                          SFIcons.sf_faceid,
                          fontSize: 32,
                          color: colors.primary,
                        )
                      : Icon(
                          Icons.fingerprint_rounded,
                          color: colors.primary,
                          size: 32,
                        ),
                ),
              )
            else
              const SizedBox(width: 75, height: 75),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyboardButton(String label, Color textColor, Color bgColor) {
    return InkWell(
      onTap: () => _onNumberPress(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
