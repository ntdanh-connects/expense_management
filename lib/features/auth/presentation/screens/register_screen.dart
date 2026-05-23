import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/presentation/widgets/auth_text_field.dart';
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
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        registered: (successMessage){
          if(successMessage != null){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                successMessage,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: colors.incomeGreen,
              duration: const Duration(seconds: 2),
              ),
            ); 
          }
          //context.go(RoutePaths.login);
        },
        error: (message) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: 
            Text(message,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
            backgroundColor: colors.expenseRed,
          )
        ),
        orElse: () {},
      );
    });

    final isLoading = authState.maybeWhen(authenticating: () => true, orElse: () => false);

    

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text('SavvyFinance', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Kiểm soát tài chính, làm chủ tương lai.', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(24)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Text('Tạo tài khoản mới', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 20),

                      AuthTextField(controller: _nameController, hintText: 'Họ tên', prefixIcon: Icons.person_outline, enabled: !isLoading, validator: (val) => (val == null || val.isEmpty) ? 'Nhập họ tên ní ơi!' : null),
                      const SizedBox(height: 16),
                      
                      AuthTextField(controller: _emailController, hintText: 'Email', prefixIcon: Icons.email_outlined, enabled: !isLoading, validator: (val) => (val == null || !val.contains('@')) ? 'Email sai cú pháp rồi!' : null),
                      const SizedBox(height: 16),
                      
                      AuthTextField(controller: _passwordController, hintText: 'Mật khẩu', prefixIcon: Icons.lock_outline, obscureText: true, enabled: !isLoading, validator: (val) => (val == null || val.length < 6) ? 'Mật khẩu từ 6 ký tự nhen!' : null),
                      const SizedBox(height: 16),
                      
                      AuthTextField(controller: _confirmPasswordController, hintText: 'Xác nhận mật khẩu', prefixIcon: Icons.refresh_outlined, obscureText: true, enabled: !isLoading, validator: (val) => val != _passwordController.text ? 'Mật khẩu không khớp!' : null),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Checkbox(value: _isAgreed, activeColor: colors.primary, onChanged: isLoading ? null : (val) => setState(() => _isAgreed = val ?? false)),
                          Expanded(child: Text('Tôi đồng ý với Điều khoản & Chính sách bảo mật của Capital.', style: TextStyle(fontSize: 13, color: colors.textSecondary))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (isLoading || !_isAgreed) ? null : () {
                            if (_formKey.currentState!.validate()) {
                              ref.read(authNotifierProvider.notifier).register(_nameController.text.trim(), _emailController.text.trim(), _passwordController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: colors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('Đăng ký ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Icon(Icons.arrow_forward_rounded, color: Colors.white)]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Đã có tài khoản? ', style: TextStyle(color: colors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go(RoutePaths.login),
                    child: Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}