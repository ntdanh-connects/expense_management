import '../../domain/entities/user_entity.dart';
import '../models/auth_response_dto.dart';

class AuthMapper {
  static UserEntity toUserEntity(UserDataDto dto) {
    return UserEntity(
      id: dto.userId,
      email: dto.email,
      fullName: dto.profile.fullName,
      avatarUrl: dto.profile.avatarUrl,
      currency: dto.preference.currency,
      language: dto.preference.language,
      theme: dto.preference.theme,
    );
  }
}