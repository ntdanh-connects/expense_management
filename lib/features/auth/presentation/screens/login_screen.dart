import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/presentation/widgets/auth_header_action.dart';
import 'package:expense_management/shared/widgets/custom_text_field.dart';
import 'package:expense_management/shared/widgets/github_logo.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/shared/widgets/modern_em_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

import 'package:expense_management/features/auth/data/service/social_auth_service.dart';
import 'package:expense_management/features/auth/presentation/widgets/safe_account_linking_bottom_sheet.dart';
import 'package:expense_management/features/auth/presentation/widgets/dev_bypass_dialog.dart';

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ElegantNotification.error(
                title: Text(
                  'login_failed'.tr(ref),
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
            }
          });
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
                      const ModernEMLogo(size: 80, showShadow: true),
                      const SizedBox(height: 16),

                      // Đổi tên thương hiệu chuẩn chỉ SpendWise đồng bộ với Web của ní luôn!
                      Text(
                        'ExpesenManagement',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors
                              .textPrimary, // Chữ sáng màu trên nền tối nhen
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'welcome_back'.tr(ref),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'login_subtitle'.tr(ref),
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
                                'email'.tr(ref),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _emailController,
                                hintText: 'example@email.com',
                                prefixIcon: Icons.email_outlined,
                                enabled: !isLoading,
                                validator: (val) =>
                                    (val == null || !val.contains('@'))
                                    ? 'email_invalid'.tr(ref)
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'password'.tr(ref),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.push(RoutePaths.forgotPassword);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'forgot_password'.tr(ref),
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
                                return CustomTextField(
                                controller: _passwordController,
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: obscurePassword,
                                enabled: !isLoading,
                                suffixIcon: obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                onPressSuffixIcon: () =>  _obscurePasswordNotifier.value = !_obscurePasswordNotifier.value,
                                validator: (val) =>
                                    (val == null || val.length < 8)
                                    ? 'password_min_len'.tr(ref)
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
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'sign_in'.tr(ref),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Icon(
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
                        'or_login_with'.tr(ref),
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            child: const GoogleLogo(size: 28),
                            colors: colors,
                            isLoading: isLoading,
                            onTap: _handleGoogleSignIn,
                          ),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            child: GithubLogo(
                              size: 28,
                              color: colors.textPrimary,
                            ),
                            colors: colors,
                            isLoading: isLoading,
                            onTap: _handleGitHubSignIn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'no_account'.tr(ref),
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => context.go(RoutePaths.register),
                            child: Text(
                              'register_now'.tr(ref),
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

  Future<void> _handleGoogleSignIn() async {
    try {
      final idToken = await SocialAuthService.signInWithGoogle();
      AppLogger.info("☁️ [Google-Auth] Lấy ID Token thành công! Đang gửi lên Server...", tag: "OAuth");
      
      final response = await ref.read(authNotifierProvider.notifier).loginWithSocial('google', idToken);
      if (response != null && response.status == 'requires_linking') {
        _showLinkingDialog(response.linkToken!, response.email!, 'Google');
      }
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [Google-Auth] Lỗi trong quá trình Google Sign-In: $e", tag: "OAuth", stackTrace: stackTrace);
      if (kDebugMode) {
        _showDevBypassDialog('google');
      } else {
        _showErrorNotification("Lỗi đăng nhập Google: $e");
      }
    }
  }

  Future<void> _handleGitHubSignIn() async {
    try {
      final code = await SocialAuthService.signInWithGitHub();
      AppLogger.info("☁️ [GitHub-Auth] Lấy Code thành công! Mã code: $code", tag: "OAuth");
      
      final response = await ref.read(authNotifierProvider.notifier).loginWithSocial('github', code);
      if (response != null && response.status == 'requires_linking') {
        _showLinkingDialog(response.linkToken!, response.email!, 'GitHub');
      }
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [GitHub-Auth] Lỗi trong quá trình GitHub Sign-In: $e", tag: "OAuth", stackTrace: stackTrace);
      if (kDebugMode) {
        _showDevBypassDialog('github');
      } else {
        _showErrorNotification("Lỗi đăng nhập GitHub: $e");
      }
    }
  }

  void _showDevBypassDialog(String provider) {
    DevBypassDialog.show(
      context,
      provider: provider,
      onBypassSubmitted: (email) async {
        final mockToken = "mock_${provider}_$email";
        AppLogger.info("🌐 [Dev-Bypass] Bắt đầu đăng nhập bằng Token giả lập: $mockToken", tag: "OAuth");
        
        final response = await ref.read(authNotifierProvider.notifier).loginWithSocial(provider, mockToken);
        if (response != null && response.status == 'requires_linking') {
          _showLinkingDialog(response.linkToken!, response.email!, provider);
        }
      },
    );
  }

  void _showLinkingDialog(String linkToken, String email, String provider) {
    SafeAccountLinkingBottomSheet.show(
      context,
      linkToken: linkToken,
      email: email,
      provider: provider,
    );
  }

  void _showErrorNotification(String message) {
    final colors = context.colors;
    ElegantNotification.error(
      title: Text(
        'error_occurred'.tr(ref),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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

  Widget _buildSocialButton({
    required Widget child,
    required AppColorsExtension colors,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.authCardBg,
          border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
        ),
        child: child,
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.24
      ..strokeCap = StrokeCap.butt;

    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - paint.strokeWidth / 2);

    // 1. Red Segment (Top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.4, 1.2, false, paint);

    // 2. Yellow Segment (Left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.6, 1.2, false, paint);

    // 3. Green Segment (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.4, false, paint);

    // 4. Blue Segment & Horizontal Bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.2, 2.0, false, paint);

    // Draw the horizontal bar
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final double barHeight = size.height * 0.24;
    final Rect barRect = Rect.fromLTWH(
      size.width * 0.5,
      size.height * 0.38,
      size.width * 0.44,
      barHeight,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
