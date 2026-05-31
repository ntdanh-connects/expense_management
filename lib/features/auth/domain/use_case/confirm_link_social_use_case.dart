import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_management/shared/domain/user_entity.dart';

class ConfirmLinkSocialUseCase {
  final AuthRepository _authRepository;

  ConfirmLinkSocialUseCase(this._authRepository);

  Future<UserEntity> execute(String linkToken, String password) async {
    return await _authRepository.confirmLinkSocial(linkToken, password);
  }
}
