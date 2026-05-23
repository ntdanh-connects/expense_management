import 'dart:async';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/presentation/screens/login_screen.dart';
import 'package:expense_management/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class RoutePaths {
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(
    ref.read(authNotifierProvider.notifier).stream,
  );
  
  ref.onDispose(() {
    refreshListenable.dispose();
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen (Chưa cài đặt UI)')),
        ),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      // 🛡️ CHUẨN BÀI: Chỉ đá về Login nếu state ĐÚNG LÀ unauthenticated thuần túy
      final isUnauthenticated = authState.maybeWhen(
        unauthenticated: () => true,
        orElse: () => false,
      );

      final isGoingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Nếu thực sự chưa đăng nhập/hết hạn token + cố tình vào trang trong -> Mới đá về login
      if (isUnauthenticated && !isGoingToAuth) {
        return '/login';
      }

      // Nếu đã authenticated (đăng nhập rồi) + cố tình quay lại auth -> Đá ra đảo Dashboard
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      if (isAuthenticated && isGoingToAuth) {
        return '/';
      }

      return null; // Các trạng thái error, registered, authenticating -> ĐỨNG IM TẠI CHỖ!
    },
  );
});

