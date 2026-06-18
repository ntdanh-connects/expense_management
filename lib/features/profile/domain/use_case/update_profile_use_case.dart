import 'package:expense_management/shared/domain/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateProfileUseCase {
  final UserRepository _userRepository;

  UpdateProfileUseCase(this._userRepository);

  Future<UserEntity> execute({
    String? fullName,
    String? language,
    String? currency,
    String? timezone,
    String? theme,
    int? financialStartDay,
  }) async {
    return await _userRepository.updateProfile(
      fullName: fullName,
      language: language,
      currency: currency,
      timezone: timezone,
      theme: theme,
      financialStartDay: financialStartDay,
    );
  }
}