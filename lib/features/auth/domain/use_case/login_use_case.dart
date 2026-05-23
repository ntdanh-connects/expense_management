import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;
  LoginUseCase(this._authRepository);

  Future<UserEntity> execute(String email, String password) async{
    return await _authRepository.loginWithEmailPassword(email, password);
  }
}