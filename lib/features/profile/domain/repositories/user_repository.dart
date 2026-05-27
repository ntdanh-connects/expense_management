import 'package:expense_management/features/auth/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Cập nhật họ tên của người dùng lên hệ thống
  Future<UserEntity> updateProfile({required String fullName});
}