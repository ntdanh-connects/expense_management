import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SafeAccountLinkingBottomSheet extends ConsumerStatefulWidget {
  final String linkToken;
  final String email;
  final String provider;

  const SafeAccountLinkingBottomSheet({
    super.key,
    required this.linkToken,
    required this.email,
    required this.provider,
  });

  static void show(
    BuildContext context, {
    required String linkToken,
    required String email,
    required String provider,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeAccountLinkingBottomSheet(
        linkToken: linkToken,
        email: email,
        provider: provider,
      ),
    );
  }

  @override
  ConsumerState<SafeAccountLinkingBottomSheet> createState() =>
      _SafeAccountLinkingBottomSheetState();
}

class _SafeAccountLinkingBottomSheetState
    extends ConsumerState<SafeAccountLinkingBottomSheet> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _obscurePasswordNotifier = ValueNotifier<bool>(true);
  bool _isLinkingLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _obscurePasswordNotifier.dispose();
    super.dispose();
  }

  void _showErrorNotification(String message, AppColorsExtension colors) {
    ElegantNotification.error(
      title: Text(
        'Có lỗi xảy ra!',
        style: TextStyle(fontWeight: FontWeight.bold, color: colors.expenseRed),
      ),
      description: Text(
        message,
        style: TextStyle(color: colors.textPrimary),
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      background: colors.authCardBg.withOpacity(0.9),
      toastDuration: const Duration(seconds: 3),
      showProgressIndicator: false,
      borderRadius: BorderRadius.circular(20),
    ).show(context);
  }

  void _showSuccessNotification(String message, AppColorsExtension colors) {
    ElegantNotification.success(
      title: Text(
        'Thành công!',
        style: TextStyle(fontWeight: FontWeight.bold, color: colors.incomeGreen),
      ),
      description: Text(
        message,
        style: TextStyle(color: colors.textPrimary),
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      background: colors.authCardBg.withOpacity(0.9),
      toastDuration: const Duration(seconds: 3),
      showProgressIndicator: false,
      borderRadius: BorderRadius.circular(20),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.authCardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Liên kết tài khoản',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bảo vệ tài khoản an toàn tuyệt đối',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Email ',
                style: TextStyle(color: colors.textSecondary),
              ),
              Text(
                widget.email,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'đã được đăng ký bằng mật khẩu trước đó. Vui lòng xác thực mật khẩu của bạn để liên kết an toàn với tài khoản ${widget.provider}.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              Text(
                'Mật khẩu xác minh',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<bool>(
                valueListenable: _obscurePasswordNotifier,
                builder: (context, obscurePassword, child) {
                  return CustomTextField(
                    controller: _passwordController,
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    enabled: !_isLinkingLoading,
                    suffixIcon: obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onPressSuffixIcon: () =>
                        _obscurePasswordNotifier.value = !obscurePassword,
                    validator: (val) => (val == null || val.length < 8)
                        ? 'Mật khẩu phải từ 8 ký tự trở lên'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLinkingLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLinkingLoading = true;
                            });
                            try {
                              AppLogger.info("🌐 [Auth-Link] Bắt đầu gửi yêu cầu liên kết lên Server...", tag: "OAuth");
                              await ref.read(authNotifierProvider.notifier).confirmLinkSocial(
                                    widget.linkToken,
                                    _passwordController.text,
                                  );
                              if (mounted) {
                                Navigator.of(context).pop();
                                _showSuccessNotification("Liên kết tài khoản thành công!", colors);
                              }
                            } catch (e) {
                              AppLogger.error("🚨 [Auth-Link] Lỗi khi liên kết tài khoản: $e", tag: "OAuth");
                              if (mounted) {
                                _showErrorNotification(e.toString(), colors);
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLinkingLoading = false;
                                });
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLinkingLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Xác nhận liên kết',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
