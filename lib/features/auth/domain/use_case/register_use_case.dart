import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository authRepository;
  RegisterUseCase(this.authRepository);


  Future<dynamic> execute(String fullName, String email, String password,String passwordConfirm) async{
    return await authRepository.registerWithEmail(fullName, email, password);
  }
}