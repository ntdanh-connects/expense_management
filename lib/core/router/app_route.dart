import 'dart:async';
import 'package:expense_management/features/analytic/presentation/screens/analytic_screen.dart';
import 'package:expense_management/features/analytic/presentation/screens/category_detail_screen.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:expense_management/features/auth/presentation/screens/login_screen.dart';
import 'package:expense_management/features/auth/presentation/screens/register_screen.dart';
import 'package:expense_management/features/auth/presentation/screens/splash_screen.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:expense_management/features/dashboard/presentation/screens/main_shell_screen.dart';
import 'package:expense_management/features/dashboard/presentation/screens/recurring_create_screen.dart';
import 'package:expense_management/features/dashboard/presentation/screens/recurring_edit_screen.dart';
import 'package:expense_management/features/dashboard/presentation/screens/recurring_list_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/change_password_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/profile_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/category_management_screen.dart';
import 'package:expense_management/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:expense_management/features/transaction/presentation/screens/transaction_history_screen.dart';
import 'package:expense_management/features/transaction/presentation/screens/add_transaction_screen.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/presentation/screens/transaction_result_screen.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:expense_management/features/wallet/presentation/screens/add_wallet_screen.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/screens/budget_create_screen.dart';
import 'package:expense_management/features/budget/presentation/screens/budget_edit_screen.dart';
import 'package:expense_management/features/reporting_export/presentation/screens/export_screen.dart';
import 'package:expense_management/features/reporting_export/presentation/screens/export_history_screen.dart';
import 'package:expense_management/features/wallet/presentation/screens/qr_scanner_screen.dart';
import 'package:expense_management/features/wallet/presentation/screens/qr_transfer_confirm_screen.dart';
import 'package:expense_management/features/wallet/presentation/screens/qr_transfer_result_screen.dart';
import 'package:expense_management/features/notification/presentation/screens/notification_settings_screen.dart';
import 'package:expense_management/features/notification/presentation/screens/notification_detail_screen.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:expense_management/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:expense_management/features/security/presentation/screens/pin_setup_screen.dart';
import 'package:expense_management/features/financial_month/presentation/screens/financial_month_screen.dart';
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
  static const addTransaction = '/add-transaction';
  static const history = '/history';
  static const analytics = '/analytics';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/change-password';
  static const activeSessions = '/profile/active-sessions';
  static const forgotPassword = '/auth/forgot-password';
  static const categories = '/profile/categories';
  static const transactionResult = '/transaction-result';
  static const transactionDetail = '/transaction-detail';
  static const recurringCreate = '/dashboard/recurring/create';
  static const recurringEdit = '/dashboard/recurring/edit';
  static const recurringList = '/dashboard/recurring';
  static const budgetCreate = '/analytics/budget/create';
  static const budgetEdit = '/analytics/budget/edit';
  static const categoryDetail = '/analytics/category-detail';
  static const export = '/profile/export';
  static const exportHistory = '/profile/export-history';
  static const qrScanner = '/qr-scanner';
  static const qrTransferConfirm = '/qr-transfer-confirm';
  static const qrTransferResult = '/qr-transfer-result';
  static const notificationSettings = '/profile/notifications';
  static const notificationDetail = '/notification-detail';
  static const aiAssistant = '/ai-assistant';
  static const pinSetup = '/profile/pin-setup';
  static const financialMonth = '/profile/financial-month';
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
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
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
      GoRoute(
        path: RoutePaths.addTransaction,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final qrData = state.extra as Map<String, dynamic>?;
          return AddTransactionScreen(qrData: qrData);
        },
      ),
      GoRoute(
        path: RoutePaths.qrScanner,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: RoutePaths.qrTransferConfirm,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final payeeData = state.extra as Map<String, dynamic>;
          return QrTransferConfirmScreen(payeeData: payeeData);
        },
      ),
      GoRoute(
        path: RoutePaths.qrTransferResult,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final resultData = state.extra as Map<String, dynamic>;
          return QrTransferResultScreen(resultData: resultData);
        },
      ),
      GoRoute(
        path: RoutePaths.transactionResult,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final params = state.extra as TransactionParams;
          return TransactionResultScreen(params: params);
        },
      ),
      GoRoute(
        path: RoutePaths.transactionDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final transaction = state.extra as TransactionEntity;
          return TransactionDetailScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: RoutePaths.notificationDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final notification = state.extra as NotificationDto;
          return NotificationDetailScreen(notification: notification);
        },
      ),
      GoRoute(
        path: RoutePaths.aiAssistant,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final initialMessage = state.extra as String?;
          return AIAssistantScreen(initialMessage: initialMessage);
        },
      ),


      StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      }  ,
      branches:[
        StatefulShellBranch(routes: [
          GoRoute(path: RoutePaths.dashboard,builder: (context, state) => const DashboardScreen(),
          routes: [
            GoRoute(
              path: 'recurring',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const RecurringListScreen(),
            ),
            GoRoute(
              path: 'recurring/create',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const RecurringCreateScreen(),
            ),
            GoRoute(
              path: 'recurring/edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final rule = state.extra as RecurringRuleEntity;
                return RecurringEditScreen(rule: rule);
              },
            ),
          ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RoutePaths.history,
            builder: (context, state) {
              final initialFilter = state.extra as String?;
              return TransactionHistoryScreen(initialFilter: initialFilter);
            },
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RoutePaths.analytics,
            builder: (context, state) => const AnalyticScreen(),
            routes: [
              GoRoute(
                path: 'budget/create',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return BudgetCreateScreen(
                    preselectedCategoryId: extra?['categoryId'] as String?,
                    suggestedAmount: extra?['suggestedAmount'] as double?,
                  );
                },
              ),
              GoRoute(
                path: 'budget/edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final budget = state.extra as BudgetDto;
                  return BudgetEditScreen(budget: budget);
                },
              ),
              GoRoute(
                path: 'category-detail',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return CategoryDetailScreen(
                    categoryId: extra['categoryId'] as String,
                    categoryName: extra['categoryName'] as String,
                    categoryColor: extra['categoryColor'] as String?,
                    categoryIcon: extra['categoryIcon'] as String?,
                    type: extra['type'] as String,
                    startDate: extra['startDate'] as DateTime,
                    endDate: extra['endDate'] as DateTime,
                    timeMode: extra['timeMode'] as String,
                  );
                },
              ),
            ],
          ),
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
              GoRoute(
                path: 'change-password',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: 'active-sessions',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ActiveSessionsScreen(),
              ),
              GoRoute(
                path: 'categories',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const CategoryManagementScreen(),
              ),
              GoRoute(
                path: 'export',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ExportScreen(),
              ),
              GoRoute(
                path: 'export-history',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ExportHistoryScreen(),
              ),
              GoRoute(
                path: 'notifications',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'pin-setup',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const PinSetupScreen(),
              ),
              GoRoute(
                path: 'financial-month',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const FinancialMonthScreen(),
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
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/auth/forgot-password';

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