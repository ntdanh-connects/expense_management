import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/database/app_database.dart' as db;
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/data/mappers/auth_mapper.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/features/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_management/features/auth/domain/use_case/login_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/register_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/social_login_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/confirm_link_social_use_case.dart';
import 'package:expense_management/features/auth/data/models/social_auth_models.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class AuthNotifier extends StateNotifier<AuthState>{
  final LoginUseCase _loginUseCase;
  final RegisterUseCase registerUseCase;
  final SocialLoginUseCase _socialLoginUseCase;
  final ConfirmLinkSocialUseCase _confirmLinkSocialUseCase;
  final AuthRepository _authRepository;
  final Ref ref;
  
  StreamSubscription<db.User?>? _userSubscription;

  AuthNotifier(
    this._loginUseCase,
    this.registerUseCase,
    this._socialLoginUseCase,
    this._confirmLinkSocialUseCase,
    this._authRepository,
    this.ref,
  ) : super(const AuthState.authenticating()) {
    _init();
  }

  Future<void> _init() async {
    checkCurrentAuthStatus();
  }


  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final userEntity = await _loginUseCase.execute(email, password);
      
      //_ref.read(localeProvider.notifier).changeLocale(userEntity.language, isFromLogin: true);
      // _ref.read(themeProvider.notifier).changeTheme(userEntity.theme == 'dark');

      _startWatchingUser(userEntity.id);
    } on AppException catch (e) {
      state = AuthState.error(message: e.toString());
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<SocialAuthResponse?> loginWithSocial(String provider, String token) async {
    state = const AuthState.authenticating();
    try {
      final response = await _socialLoginUseCase.execute(provider, token);
      if (response.status == 'success') {
        _startWatchingUser(response.data!.userId);
      } else if (response.status == 'requires_linking') {
        state = const AuthState.unauthenticated(); // Keep screen unauthenticated so user can interact with modal dialog
      }
      return response;
    } on AppException catch (e) {
      state = AuthState.error(message: e.toString());
      return null;
    } catch (e) {
      state = AuthState.error(message: e.toString());
      return null;
    }
  }

  Future<void> confirmLinkSocial(String linkToken, String password) async {
    state = const AuthState.authenticating();
    try {
      final userEntity = await _confirmLinkSocialUseCase.execute(linkToken, password);
      _startWatchingUser(userEntity.id);
    } on AppException catch (e) {
      state = AuthState.error(message: e.toString());
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final successMessage = await registerUseCase.execute(fullName, email, password,password);
      
      state = AuthState.registered(message: successMessage);
    } on AppException catch (e) {
      state = AuthState.error(message: e.toString());
    } catch (e) {
      state = const AuthState.error(message: 'Đăng ký thất bại: Lỗi hệ thống.');
    }
  }


  Future<void> checkCurrentAuthStatus() async {
    final storage = ref.read(secureStorageServiceProvider);
    final localDataSource = ref.read(authLocalDataSourceProvider);

    final refreshToken = await storage.get(key: AppConstant.refreshToken);
    final userId = await storage.get(key: AppConstant.userId); 

    // Nếu mất dấu Token bảo mật hoặc chưa từng login thành công -> Đá văng ra Login
    if (refreshToken == null || userId == null) {
      _stopWatchingUser();
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      // Chọc thẳng tay vào Drift SQLite bốc hàng dữ liệu lên RAM
      final localUserRow = await localDataSource.getCachedProfile(userId);

      if (localUserRow != null) {
        _startWatchingUser(userId);
      } else {
        _stopWatchingUser();
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      _stopWatchingUser();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> syncUserProfileImplicit() async {
    try {
      // Gọi Repo bắn API lên Backend của ní lấy thông tin tươi sống mới nhất
      final freshUser = await _authRepository.syncFreshProfile();
      
      // Đè bẹp trạng thái cũ, ép UI âm thầm đổi chữ mượt mà không giật lag!
      state = AuthState.authenticated(user: freshUser);
    } catch (_) {
      // Mất mạng hay lỗi BE ,xài tiếp data cũ ở Local bình thường
    }
  }

  void _startWatchingUser(String userId) {
    _userSubscription?.cancel();
    final dbInstance = ref.read(db.appDatabaseProvider);
    _userSubscription = dbInstance.watchUserProfile(userId).listen((localUserRow) {
      if (localUserRow != null) {
        final userEntity = UserEntity(
          id: localUserRow.id,
          email: localUserRow.email,
          fullName: localUserRow.fullName,
          currency: localUserRow.currency,
          language: localUserRow.language,
          theme: localUserRow.theme,
        );
        state.maybeWhen(
          authenticated: (currentUser) {
            if (currentUser != userEntity) {
              state = AuthState.authenticated(user: userEntity);
            }
          },
          orElse: () {
            state = AuthState.authenticated(user: userEntity);
          },
        );
      }
    });
  }

  void _stopWatchingUser() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  Future<void> logout() async {
    _stopWatchingUser();

    try {
      final storage = ref.read(secureStorageServiceProvider);
      await storage.delete(key: AppConstant.accessToken);
      await storage.delete(key: AppConstant.refreshToken);
      await storage.delete(key: AppConstant.userId);
    } catch (_) {
      // Bỏ qua lỗi Keychain/SecureStorage khi dev
    }

    try {
      final dbInstance = ref.read(db.appDatabaseProvider);
      await dbInstance.clearAuthData();
    } catch (_) {
      // Bỏ qua lỗi clear DB để luôn đổi trạng thái sang unauthenticated
    }

    state = const AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _stopWatchingUser();
    super.dispose();
  }
}