import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAgreed = false;

  final ValueNotifier<bool> _obscurePasswordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _obscurePasswordConfirmNotifier = ValueNotifier(true);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        registered: (successMessage) {
          if (successMessage != null) {
            ElegantNotification(
            title: Text('Thành Công',style: TextStyle(color: colors.incomeGreen,fontWeight: FontWeight.bold),),
            description: Text(successMessage,style: TextStyle(color: colors.textPrimary),),
            animationCurve: Curves.ease,
            toastDuration: const Duration(seconds: 3),
            background: colors.background.withOpacity(0.9),
            width: MediaQuery.of(context).size.width,
            position: Alignment.topCenter,
            animation: AnimationType.fromTop,
            ).show(context);
          }
        },
        error: (message) => ElegantNotification(
            title: Text('Thất bại!',style: TextStyle(color: colors.expenseRed,fontWeight: FontWeight.bold),),
            description: Text(message,style: TextStyle(color: colors.textPrimary),),
            animationCurve: Curves.ease,
            toastDuration: const Duration(seconds: 3),
            background: colors.background.withOpacity(0.9),
            width: MediaQuery.of(context).size.width,
            position: Alignment.topCenter,
            animation: AnimationType.fromTop,
            ).show(context),
        orElse: () {},
      );
    });

    final isLoading = authState.maybeWhen(authenticating: () => true, orElse: () => false);

    return authState.when(
      authenticating: () => _buildRegisterForm(isLoading: true, colors: colors),
      unauthenticated: () => _buildRegisterForm(isLoading: false, colors: colors),
      error: (_) => _buildRegisterForm(isLoading: false, colors: colors),
      authenticated: (_) => _buildRegisterForm(isLoading: true, colors: colors),
      registered: (_) => _buildRegisterForm(isLoading: false, colors: colors),
    );
  }

  Widget _buildRegisterForm({required bool isLoading, required AppColorsExtension colors}) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: colors.authGradient, 
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ExpenseManagement',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold, 
                      color: colors.textPrimary, // Chữ sáng màu trên nền tối
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kiểm soát tài chính, làm chủ tương lai.', 
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.authCardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.textSecondary.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Hãy bắt đầu với ExpenseManagement', 
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _nameController, 
                            hintText: 'Họ tên', 
                            prefixIcon: Icons.person_outline, 
                            enabled: !isLoading, 
                            validator: (val) => (val == null || val.isEmpty) ? 'Hãy điền họ tên!' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _emailController, 
                            hintText: 'example@gmail.com',
                            prefixIcon: Icons.email_outlined, 
                            enabled: !isLoading, 
                            validator: (val) => (val == null || !val.contains('@')) ? 'Sai định dạng Email' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          ValueListenableBuilder(
                            valueListenable: _obscurePasswordNotifier,
                            builder: (_,obscurePassword,child){
                              return CustomTextField(
                            controller: _passwordController, 
                            hintText: 'Mật khẩu', 
                            prefixIcon: Icons.lock_outline, 
                            suffixIcon: obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            onPressSuffixIcon: () => _obscurePasswordNotifier.value = !_obscurePasswordNotifier.value,
                            obscureText: obscurePassword, 
                            enabled: !isLoading, 
                            validator: (val) => (val == null || val.length < 8) ? 'Mật khẩu từ 8 ký tự trở lên!' : null,
                            );
                          }),
                          const SizedBox(height: 16),
                          
                          ValueListenableBuilder(
                          valueListenable: _obscurePasswordConfirmNotifier, 
                          builder: (_,obscurePasswordConfirm,_){
                            return CustomTextField(
                            controller: _confirmPasswordController, 
                            hintText: 'Điền lại mật khẩu',
                            prefixIcon: Icons.refresh_outlined, 
                            suffixIcon: obscurePasswordConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            onPressSuffixIcon: () => _obscurePasswordConfirmNotifier.value = !_obscurePasswordConfirmNotifier.value,
                            obscureText: obscurePasswordConfirm, 
                            enabled: !isLoading, 
                            validator: (val) => val != _passwordController.text ? 'Mật khẩu không trùng khớp' : null,
                          );
                          }),
                          
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Checkbox(
                                value: _isAgreed, 
                                activeColor: colors.primary,
                                checkColor: Colors.white,
                                side: BorderSide(color: colors.textSecondary),
                                onChanged: isLoading ? null : (val) => setState(() => _isAgreed = val ?? false),
                              ),
                              Expanded(
                                child: Text(
                                  'Tôi đồng ý với Điều khoản & Chính sách bảo mật của ExpMgmt.',
                                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (isLoading || !_isAgreed) ? null : () {
                                if (_formKey.currentState!.validate()) {
                                  ref.read(authNotifierProvider.notifier).register(
                                        _nameController.text.trim(),
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24, 
                                      height: 24, 
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5, 
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center, 
                                      children: [
                                        Text('Sign Up ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), 
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Đã có tài khoản? ', style: TextStyle(color: colors.textSecondary)),
                      GestureDetector(
                        onTap: () => context.go(RoutePaths.login),
                        child: Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}