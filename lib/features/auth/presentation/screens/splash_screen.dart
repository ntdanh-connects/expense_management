import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/shared/widgets/modern_em_logo.dart';


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

    return Scaffold(
      backgroundColor: Colors.black, // Nền đen sâu làm nền phụ khi thu nhỏ
      body: Stack(
        children: [
          // 1. Màn hình nền Gradient sẽ bị co rút tròn nhỏ lại biến mất
          AnimatedBuilder(
            animation: _radiusAnimation,
            builder: (context, child) {
              return ClipPath(
                clipper: CircularShrinkClipper(progress: _radiusAnimation.value),
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: colors.authGradient,
              ),
            ),
          ),

          // 2. Khối Logo nổi hẳn lên trên và chạy hiệu ứng scale/fade mượt mà theo tiến trình thu nhỏ
          Center(
            child: AnimatedBuilder(
              animation: _radiusAnimation,
              builder: (context, child) {
                final double progress = _radiusAnimation.value;
                // Logo giữ nguyên độ đậm nét 100% trong phần lớn thời gian co rút nền,
                // và chỉ nhanh chóng mờ dần trong 20% tiến trình cuối (từ 0.2 về 0.0)
                final double logoOpacity = (progress / 0.2).clamp(0.0, 1.0);
                
                // Logo sẽ phóng to (bay về phía người dùng) từ 1.0 lên 1.3 khi nền co rút nhỏ đi
                final double logoScale = 1.3 - 0.3 * progress;

                return Opacity(
                  opacity: logoOpacity,
                  child: Transform.scale(
                    scale: logoScale,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.35),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const ModernEMLogo(size: 90, showShadow: true),
                  ),
                ],
              ),
            ),
          ),
        ],
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