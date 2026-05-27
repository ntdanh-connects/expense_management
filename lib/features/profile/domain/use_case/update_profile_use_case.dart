import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateProfileUseCase {
  final UserRepository _userRepository;

  UpdateProfileUseCase(this._userRepository);

  Future<UserEntity> execute({required String fullName}) async {
    return await _userRepository.updateProfile(fullName: fullName);
  }
}