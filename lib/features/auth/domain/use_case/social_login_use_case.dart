import 'package:expense_management/features/auth/data/models/social_auth_models.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';

class SocialLoginUseCase {
  final AuthRepository _authRepository;

  SocialLoginUseCase(this._authRepository);

  Future<SocialAuthResponse> execute(String provider, String token) async {
    return await _authRepository.loginWithSocial(provider, token);
  }
}
