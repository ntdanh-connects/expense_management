import 'package:expense_management/shared/domain/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity>loginWithEmailPassword(String email, String password);
  Future<dynamic>registerWithEmail(String fullname,String email,String password);
  Future<UserEntity> syncFreshProfile();
}