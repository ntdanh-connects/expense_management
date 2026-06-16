import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/security/presentation/providers/security_provider.dart';
import 'package:expense_management/core/language/app_language.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _tempPin = '';
  String _currentInput = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onNumberPress(String number) {
    if (_currentInput.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentInput += number;
      _errorMessage = '';
    });

    if (_currentInput.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _processPinInput);
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _errorMessage = '';
    });
  }

  Future<void> _processPinInput() async {
    if (!_isConfirming) {
      // Lưu lại mã PIN nhập lần đầu và chuyển sang bước Xác nhận
      _tempPin = _currentInput;
      setState(() {
        _currentInput = '';
        _isConfirming = true;
      });
    } else {
      // Kiểm tra xác nhận trùng khớp
      if (_tempPin == _currentInput) {
        final notifier = ref.read(securityNotifierProvider.notifier);
        await notifier.enablePin(_currentInput);

        // Kiểm tra xem thiết bị có hỗ trợ FaceID/Vân tay không để gợi ý bật luôn
        final hasBiometrics = await notifier.checkBiometricSupport();
        if (hasBiometrics && mounted) {
          _showBiometricOptInDialog();
        } else {
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        // Nhập không trùng khớp, yêu cầu làm lại
        HapticFeedback.vibrate();
        setState(() {
          _currentInput = '';
          _tempPin = '';
          _isConfirming = false;
          _errorMessage = 'pin_mismatch_error'.trRead(ref);
        });
      }
    }
  }

  Future<void> _showBiometricOptInDialog() async {
    final colors = context.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'opt_in_biometrics_title'.trRead(ref),
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'opt_in_biometrics_desc'.trRead(ref),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: Text(
              'skip'.trRead(ref),
              style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              await ref.read(securityNotifierProvider.notifier).setBiometricEnabled(true);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context, true);
            },
            child: Text(
              'agree_enable'.trRead(ref),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sử dụng authGradient cho nền đồng bộ
    final backgroundGradient = isDark 
        ? colors.authGradient 
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.background, colors.background.withOpacity(0.95)],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header với nút quay lại
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, 
                        color: isDark ? Colors.white : colors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'pin_setup_title'.tr(ref),
                    style: TextStyle(
                      color: isDark ? Colors.white : colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer để cân đối tiêu đề ở giữa
                ],
              ),
              const Spacer(flex: 1),

              // Shield Icon
              Icon(
                Icons.security_rounded,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: 24),

              // Title hướng dẫn
              Text(
                _isConfirming ? 'pin_confirm_title'.tr(ref) : 'pin_create_title'.tr(ref),
                style: TextStyle(
                  color: isDark ? Colors.white : colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'pin_setup_desc'.tr(ref),
                style: TextStyle(
                  color: isDark ? Colors.white60 : colors.textSecondary,
                  fontSize: 13,
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

              const Spacer(flex: 2),

              // Bàn phím số numeric keypad
              _buildKeyboard(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(bool isDark) {
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
            // Ô trống bên trái
            const SizedBox(width: 75, height: 75),
            _buildKeyboardButton('0', buttonTextColor, buttonBgColor),
            // Nút Backspace bên phải
            InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 75,
                height: 75,
                alignment: Alignment.center,
                child: Icon(Icons.backspace_outlined, color: buttonTextColor, size: 24),
              ),
            ),
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
