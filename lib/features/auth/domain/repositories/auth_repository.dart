import 'package:expense_management/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity>loginWithEmailPassword(String email, String password);
  Future<dynamic>registerWithEmail(String fullname,String email,String password);
}