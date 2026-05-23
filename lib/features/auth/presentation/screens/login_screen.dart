import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: const TextStyle(color: Colors.white)),
              backgroundColor: context.colors.expenseRed
            ),
          );
        },
        authenticated: (user) {
          // context.go('/home');
        },
        orElse: () {},
      );
    });

    return authState.when(
     
      authenticating: () => _buildLoginForm(isLoading: true),//Replace = Home_skeleton
      
      unauthenticated: () => _buildLoginForm(isLoading: false),
      error: (_) => _buildLoginForm(isLoading: false),
      
      authenticated: (_) => _buildLoginForm(isLoading: true),

      registered: (_) => _buildLoginForm(isLoading: false)
    );
  }

  Widget _buildLoginForm({required bool isLoading}) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Capital',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
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
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                      const SizedBox(height: 8),
                      AuthTextField(
                        controller: _emailController,
                        hintText: 'example@email.com',
                        prefixIcon: Icons.email_outlined,
                        enabled: !isLoading,
                        validator: (val) => (val == null || !val.contains('@')) ? 'Email sai định dạng!' : null,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                          TextButton(
                            onPressed: isLoading ? null : () {},
                            child: Text('Quên mật khẩu?', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      AuthTextField(
                        controller: _passwordController,
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        enabled: !isLoading,
                        suffixIcon: Icon(Icons.visibility_outlined, color: colors.textSecondary),
                        validator: (val) => (val == null || val.length < 6) ? 'Vui lòng mật khẩu phải từ 6 ký tự trở lên!' : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    ref.read(authNotifierProvider.notifier).login(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            disabledBackgroundColor: colors.primary.withOpacity(0.5),
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Đăng nhập ',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Hoặc đăng nhập bằng', style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBiometricButton(icon: Icons.fingerprint_rounded, colors: colors),
                  const SizedBox(width: 20),
                  _buildBiometricButton(icon: Icons.face_retouching_natural, colors: colors),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có tài khoản? ', style: TextStyle(color: colors.textSecondary)),
                  GestureDetector(
                    onTap: isLoading ? null : () => context.go(RoutePaths.register),
                    child: Text(
                      'Đăng ký ngay',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton({required IconData icon, required AppColorsExtension colors}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
      ),
      child: Icon(icon, size: 28, color: colors.primary),
    );
  }
}