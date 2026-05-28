
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;

  const factory AuthState.authenticating() = _Authenticating;

  const factory AuthState.authenticated({required UserEntity user}) = _Authenticated;

  const factory AuthState.error({required String message}) = _Error;

  const factory AuthState.registered({String? message}) = _Registered;
}