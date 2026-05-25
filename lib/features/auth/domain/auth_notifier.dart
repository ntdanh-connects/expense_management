import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/data/mappers/auth_mapper.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_management/features/auth/domain/use_case/login_use_case.dart';
import 'package:expense_management/features/auth/domain/use_case/register_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class AuthNotifier extends StateNotifier<AuthState>{
  final LoginUseCase _loginUseCase;
  final RegisterUseCase registerUseCase;
  final Ref ref;
  AuthNotifier(this._loginUseCase,this.registerUseCase,this.ref): super(const AuthState.authenticating()) {
    _init();
  }

  Future<void> _init() async {
    // Chờ 2 giây hiển thị màn hình Splash trước khi chuyển sang trạng thái chưa đăng nhập
    await Future.delayed(const Duration(seconds: 2));
    checkCurrentAuthStatus();
  }


  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final userEntity = await _loginUseCase.execute(email, password);
      
      //_ref.read(localeProvider.notifier).changeLocale(userEntity.language, isFromLogin: true);
      // _ref.read(themeProvider.notifier).changeTheme(userEntity.theme == 'dark');

      state = AuthState.authenticated(user: userEntity);
    } on AppException catch (e) {
      state = AuthState.error(message: e.toString());
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    state = const AuthState.authenticating();
    try {
      // Hứng chuỗi chữ "Đăng kí tài khoản thành công" từ UseCase
      final successMessage = await registerUseCase.execute(fullName, email, password,password);
      
      // Trả trạng thái về chưa đăng nhập để giữ form, đẩy thông điệp thành công ra ngoài
      state = AuthState.registered(message: successMessage);
    } on AppException catch (e) {
      state = AuthState.error(message: e.toString());
    } catch (e) {
      state = const AuthState.error(message: 'Đăng ký thất bại: Lỗi hệ thống.');
    }
  }


  Future<void> checkCurrentAuthStatus() async {

    final storage = ref.read(secureStorageServiceProvider);
    final token = await storage.get(key: AppConstant.accessToken);
    final userJsonString = await storage.get(key: 'cached_user_profile');

    if (token != null && userJsonString != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJsonString);
        final userEntity = AuthMapper.toUserEntity(UserDataDto.fromJson(userMap));
        
        state = AuthState.authenticated(user: userEntity);
        return;
      } catch (_) {
        state = const AuthState.unauthenticated();
        return;
      }
    }

    // Nếu không có token -> Đẩy về unauthenticated để GoRouter đá về Login
    state = const AuthState.unauthenticated();
  }
}