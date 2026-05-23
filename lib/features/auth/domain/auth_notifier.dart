import 'package:dio/dio.dart';
import 'package:expense_management/core/error/app_exception.dart';
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
  AuthNotifier(this._loginUseCase,this.registerUseCase,this.ref): super(const AuthState.unauthenticated());


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
}