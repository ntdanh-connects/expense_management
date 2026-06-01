import 'dart:io';
import 'package:expense_management/shared/domain/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateAvatarUseCase {
  final UserRepository _userRepository;

  UpdateAvatarUseCase(this._userRepository);

  Future<UserEntity> execute({required File imageFile}) async {
    return await _userRepository.updateAvatar(imageFile: imageFile);
  }
}