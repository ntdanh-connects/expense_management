import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/change_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/language/app_language.dart';

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
        SnackBar(
          content: Text('change_password_success_relogin'.tr(ref)),
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
      String displayError = 'change_password_failed'.tr(ref);

      if (passwordState is AsyncError) {
        displayError = passwordState.error.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'failed_prefix'.tr(ref)}: $displayError'),
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
        title: Text('change_password'.tr(ref)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'change_password_desc'.tr(ref),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _buildPasswordField(
                label: 'current_password'.tr(ref),
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'please_enter_current_password'.tr(ref);
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
                    'forgot_password_q'.tr(ref),
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
                label: 'new_password'.tr(ref),
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'please_enter_new_password'.tr(ref);
                  if (val.length < 6) return 'password_min_len_6'.tr(ref);
                  if (val == _oldPasswordController.text) return 'new_password_same_as_old_error'.tr(ref);
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              _buildPasswordField(
                label: 'confirm_new_password'.tr(ref),
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'please_confirm_new_password'.tr(ref);
                  if (val != _newPasswordController.text) return 'passwords_do_not_match'.tr(ref);
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
                      : Text(
                          'update_password'.tr(ref),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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