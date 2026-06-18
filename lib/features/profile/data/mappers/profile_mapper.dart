import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/shared/domain/user_entity.dart';

class ProfileMapper {
  static UserEntity toUserEntity(UserDataDto dto) {
    return UserEntity(
      id: dto.userId,
      email: dto.email,
      fullName: dto.profile.fullName,
      avatarUrl: dto.profile.avatarUrl,
      currency: dto.preference.currency,
      language: dto.preference.language,
      theme: dto.preference.theme,
      timezone: dto.preference.timezone,
      financialStartDay: dto.preference.financialStartDay,
    );
  }
}