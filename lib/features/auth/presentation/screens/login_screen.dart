import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/presentation/widgets/auth_header_action.dart';
import 'package:expense_management/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final ValueNotifier<bool> _obscurePasswordNotifier = ValueNotifier(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (message) {
          ElegantNotification.error(
            title: Text(
              'Đăng nhập thất bại!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.expenseRed,
              ),
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
            width: MediaQuery.of(context).size.width,
          ).show(context);
        },
        authenticated: (user) {},
        orElse: () {},
      );
    });

    // Trích xuất trạng thái đợi API mạng
    final isLoading = authState.maybeWhen(
      authenticating: () => true,
      orElse: () => false,
    );

    return authState.when(
      authenticating: () => _buildLoginForm(isLoading: true, colors: colors),
      unauthenticated: () => _buildLoginForm(isLoading: false, colors: colors),
      error: (_) => _buildLoginForm(isLoading: false, colors: colors),
      authenticated: (_) => _buildLoginForm(isLoading: true, colors: colors),
      registered: (_) => _buildLoginForm(isLoading: false, colors: colors),
    );
  }

  Widget _buildLoginForm({
    required bool isLoading,
    required AppColorsExtension colors,
  }) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: colors.authGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: colors.authGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 44,
                        )
                      ),
                      const SizedBox(height: 16),

                      // Đổi tên thương hiệu chuẩn chỉ SpendWise đồng bộ với Web của ní luôn!
                      Text(
                        'SpendWise',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors
                              .textPrimary, // Chữ sáng màu trên nền tối nhen
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Chào mừng trở lại',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng đăng nhập để tiếp tục quản lý tài chính',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors
                              .authCardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.textSecondary.withOpacity(
                              0.1,
                            ), // Viền mờ chống đơn điệu
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
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AuthTextField(
                                controller: _emailController,
                                hintText: 'example@email.com',
                                prefixIcon: Icons.email_outlined,
                                enabled: !isLoading,
                                validator: (val) =>
                                    (val == null || !val.contains('@'))
                                    ? 'Email sai định dạng!'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Mật khẩu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isLoading ? null : () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'Quên mật khẩu?',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ValueListenableBuilder(valueListenable: _obscurePasswordNotifier, builder: 
                              (context,obscurePassword,child){
                                return AuthTextField(
                                controller: _passwordController,
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: obscurePassword,
                                enabled: !isLoading,
                                suffixIcon: obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                onPressSuffixIcon: () =>  _obscurePasswordNotifier.value = !_obscurePasswordNotifier.value,
                                validator: (val) =>
                                    (val == null || val.length < 8)
                                    ? 'Mật khẩu phải từ 8 ký tự trở lên'
                                    : null,
                                );
                              }),
                              
                              const SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            ref.read(authNotifierProvider.notifier).login(
                                                  _emailController.text.trim(),
                                                  _passwordController.text,
                                                );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    disabledBackgroundColor: colors.primary
                                        .withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign In ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Hoặc đăng nhập bằng',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBiometricButton(
                            icon: Icons.fingerprint_rounded,
                            colors: colors,
                            isLoading: isLoading,
                          ),
                          const SizedBox(width: 20),
                          _buildBiometricButton(
                            icon: Icons.face_retouching_natural,
                            colors: colors,
                            isLoading: isLoading,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => context.go(RoutePaths.register),
                            child: Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(child: AuthHeaderAction())
        ],
      ),
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required AppColorsExtension colors,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.authCardBg,
          border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 28, color: colors.primary),
      ),
    );
  }
}
