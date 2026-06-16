import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/security/presentation/providers/security_provider.dart';
import 'package:expense_management/features/security/presentation/screens/pin_lock_screen.dart';

class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager> with WidgetsBindingObserver {
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final securityState = ref.read(securityNotifierProvider);
    
    // Chỉ xử lý nếu tính năng khóa PIN đã được bật
    if (!securityState.isPinEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Ghi nhận thời điểm app xuống background (nếu chưa ghi nhận trước đó)
      _backgroundTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final elapsed = DateTime.now().difference(_backgroundTime!);
        // Nếu app ở dưới background quá 15 giây, thực hiện khóa màn hình
        if (elapsed.inSeconds >= 15) {
          ref.read(securityNotifierProvider.notifier).lock();
        }
        // Reset thời điểm background
        _backgroundTime = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityNotifierProvider);

    return Directionality(
      // Kế thừa text direction mặc định của app
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (securityState.isLocked)
            const Positioned.fill(
              child: PinLockScreen(),
            ),
        ],
      ),
    );
  }
}
