import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/auth_provider.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Khởi tạo bộ đếm thời gian chạy hiệu ứng lướt (Thời gian co rút là 700 mili-giây)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 2. Thiết lập đường cong lò xo biến hình: Đi từ 1.0 (toàn màn hình) về 0.0 (thu nhỏ biến mất)
    _radiusAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurveTween(curve: Curves.easeInOutQuart).animate(_animationController),
    );

    // ⚡ CHỐT CHẶN KÍCH NỔ: Ngắm nghía logo 2 giây, sau đó tự động co rút lại!
    _startSplashLifecycle();
  }

  void _startSplashLifecycle() async {
    // Cho người dùng ngắm logo SpendWise 2 giây sang chảnh
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // KÍCH NỔ HIỆU ỨNG THU TRÒN CO RÚT BẬT VÈO LÊN!
    await _animationController.forward();

    // Hiệu ứng chạy xong xuôi -> Đưa quyền sinh sát check Token điều hướng lại cho GoRouter gánh!
    if (mounted) {
      // Đặt splashCompletedProvider = true để báo cho GoRouter biết rằng đã xong Splash
      ref.read(splashCompletedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _radiusAnimation,
      builder: (context, child) {
        // 🔮 THẦN CHÚ CẮT GỌT: Bọc CustomClipper để khoét cái lỗ tròn co rút màn hình!
        return ClipPath(
          clipper: CircularShrinkClipper(progress: _radiusAnimation.value),
          child: child,
        );
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: colors.authGradient, // Nền Gradient BankDash lộng lẫy của ní
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 👤 KHỐI TRÒN AVATAR LOGO TÂM ĐIỂM
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/app_logo_dark.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ExpenseManagement',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// 📐 THUẬT TOÁN TOÁN HỌC HÌNH HỌC: KHOÉT LỖ TRÒN CO RÚT MÀN HÌNH (CLIPPER)
// ======================================================================
class CircularShrinkClipper extends CustomClipper<Path> {
  final double progress;
  CircularShrinkClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Nếu chưa chạy hiệu ứng, giữ nguyên vẹn toàn bộ lề màn hình phẳng
    if (progress >= 1.0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // Tâm của lỗ tròn co rúm đặt chính giữa màn hình (Trùng tọa độ của cái Logo luôn)
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // Công thức tính bán kính đường chéo màn hình để bao trùm vô cực
    final double maxRadius = Offset(size.width, size.height).distance;
    final double currentRadius = maxRadius * progress;

    // Khoét cái hình tròn nhỏ dần nhỏ dần theo thời gian thực!
    path.addOval(Rect.fromCircle(center: center, radius: currentRadius));
    return path;
  }

  @override
  bool shouldReclip(covariant CircularShrinkClipper oldClipper) {
    return oldClipper.progress != progress; // Ép re-render liên tục theo frame để mượt 120Hz
  }
}