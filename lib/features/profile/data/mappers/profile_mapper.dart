import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';

class ProfileMapper {
  /// Chuyển đổi dữ liệu thô nhận được từ API Update Profile thành Entity sạch cho UI dùng
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