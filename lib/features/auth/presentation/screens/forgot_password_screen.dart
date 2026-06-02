import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/forgot_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    
    // Gọi API thông qua RiverpodNotifier
    final success = await ref.read(forgotPasswordProvider.notifier).sendResetLink(email);

    if (mounted) {
      if (success) {
        // Thông báo thành công
        ElegantNotification.success(
          title: const Text("Thành công", style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text("Liên kết đặt lại mật khẩu đã được gửi đến $email"),
          // notificationPosition: NotificationPosition.topCenter,
          animation: AnimationType.fromTop,
        ).show(context);
        
        // Quay lại màn hình Đăng nhập sau khi gửi thành công
        context.pop();
      } else {
        // Lấy thông báo lỗi từ state ra hiển thị
        final errorState = ref.read(forgotPasswordProvider);
        String errorMsg = "Gửi yêu cầu thất bại. Vui lòng thử lại!";
        
        errorState.whenOrNull(
          error: (error, _) {
            errorMsg = error.toString().replaceAll('Exception: ', '');
          },
        );

        ElegantNotification.error(
          title: const Text("Thất bại", style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text(errorMsg),
          // notificationPosition: NotificationPosition.topCenter,
          animation: AnimationType.fromTop,
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Theo dõi trạng thái loading từ Riverpod
    final forgotPasswordState = ref.watch(forgotPasswordProvider);
    final isLoading = forgotPasswordState is AsyncLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đừng lo lắng! Hãy nhập email đã đăng ký của bạn vào bên dưới, chúng tôi sẽ gửi liên kết để đặt lại mật khẩu mới.',
                style: TextStyle(
                  fontSize: 15,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Ô nhập Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading, // Khóa input khi đang gọi API
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Email không đúng định dạng';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Địa chỉ Email',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Nút Gửi yêu cầu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSubmit,
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
                          'Gửi yêu cầu',
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
}