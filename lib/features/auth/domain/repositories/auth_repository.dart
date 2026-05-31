import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:expense_management/features/auth/data/models/social_auth_models.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithEmailPassword(String email, String password);
  Future<dynamic> registerWithEmail(String fullname, String email, String password);
  Future<UserEntity> syncFreshProfile();
  
  Future<SocialAuthResponse> loginWithSocial(String provider, String token);
  Future<UserEntity> confirmLinkSocial(String linkToken, String password);
}