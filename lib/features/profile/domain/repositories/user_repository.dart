import 'package:expense_management/shared/domain/user_entity.dart';

abstract class UserRepository {
  /// Cập nhật họ tên của người dùng lên hệ thống
  Future<UserEntity> updateProfile({required String fullName});
}