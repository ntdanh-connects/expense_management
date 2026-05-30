import 'dart:async';
import 'package:expense_management/features/analytic/presentation/screens/analytic_screen.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/presentation/screens/login_screen.dart';
import 'package:expense_management/features/auth/presentation/screens/register_screen.dart';
import 'package:expense_management/features/auth/presentation/screens/splash_screen.dart';
import 'package:expense_management/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:expense_management/features/dashboard/presentation/screens/main_shell_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/profile_screen.dart';
import 'package:expense_management/features/transaction/presentation/screens/transaction_history_screen.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:expense_management/features/wallet/presentation/screens/add_wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const wallet = '/wallet';
  static const addWallet = '/add-wallet';
  static const history = '/history';
  static const analytics = '/analytics';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  void refresh() {
    notifyListeners();
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
  
  ref.listen<bool>(splashCompletedProvider, (previous, next) {
    refreshListenable.refresh();
  });
  
  ref.onDispose(() {
    refreshListenable.dispose();
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Trả về child phẳng lỳ, tắt sạch hiệu ứng chuyển trang mặc định của hệ thống 
            // để nhường sân khấu cho cục ClipPath toán học tự xử lý!
            return child; 
          },
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.wallet,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.addWallet,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final wallet = state.extra as WalletEntity?;
          return AddWalletScreen(walletToEdit: wallet);
        },
      ),

      StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      }  ,
      branches:[
        StatefulShellBranch(routes: [
          GoRoute(path: RoutePaths.dashboard,builder: (context, state) => const DashboardScreen(),),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: RoutePaths.history,builder: (context, state) => const TransactionHistoryScreen(),),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: RoutePaths.analytics,builder: (context, state) => const AnalyticScreen(),),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => ProfileScreen(
              onLogout: () {
                ref.read(authNotifierProvider.notifier).logout();
              },
            ),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const PersonalInfoScreen(),
              ),
            ],
          ),
        ]),
      ] )
    ],
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final splashCompleted = ref.read(splashCompletedProvider);

      // Nếu đang ở splash và splash chưa hoàn thành thì đứng im tại splash!
      if (state.matchedLocation == '/splash' && !splashCompleted) {
        return null;
      }

      final isUnauthenticated = authState.maybeWhen(
        unauthenticated: () => true,
        orElse: () => false,
      );

      final isGoingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isUnauthenticated && !isGoingToAuth) {
        return '/login';
      }

      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      
      final isGoingToAuthOrSplash =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      if (isAuthenticated && isGoingToAuthOrSplash) {
        return RoutePaths.dashboard;
      }

      return null; // Các trạng thái error, registered, authenticating -> ĐỨNG IM TẠI CHỖ!
    },
  );
});

