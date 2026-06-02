import 'package:expense_management/shared/domain/user_entity.dart';

import 'dart:io';

abstract class UserRepository {
  /// Cập nhật thông tin hồ sơ của người dùng lên hệ thống
  Future<UserEntity> updateProfile({String? fullName, String? language});

  // Cập nhật avatar của người dùng lên hệ thống
  Future<UserEntity> updateAvatar({required File imageFile});
}