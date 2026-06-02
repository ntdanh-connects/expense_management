import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/change_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(changePasswordProvider.notifier).changePassword(
          oldPassword: _oldPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
          confirmPassword: _confirmPasswordController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.delete(key: AppConstant.accessToken);
      await secureStorage.delete(key: AppConstant.userId);

      if (mounted) {
        context.go(RoutePaths.login); 
      }
    } else {
      final passwordState = ref.read(changePasswordProvider);
      String displayError = 'Đổi mật khẩu thất bại. Vui lòng thử lại!';

      if (passwordState is AsyncError) {
        displayError = passwordState.error.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thất bại: $displayError'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final passwordState = ref.watch(changePasswordProvider);
    final isLoading = passwordState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo mật khẩu mới cho tài khoản của bạn để đảm bảo tính an toàn bảo mật.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _buildPasswordField(
                label: 'Mật khẩu hiện tại',
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.push(RoutePaths.forgotPassword);
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildPasswordField(
                label: 'Mật khẩu mới',
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
                  if (val == _oldPasswordController.text) return 'Mật khẩu mới không được trùng mật khẩu cũ';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              _buildPasswordField(
                label: 'Xác nhận mật khẩu mới',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                  if (val != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Cập nhật mật khẩu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}