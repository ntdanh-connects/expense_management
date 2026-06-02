import 'package:expense_management/shared/domain/user_entity.dart';

import 'dart:io';

abstract class UserRepository {
  /// Cập nhật họ tên của người dùng lên hệ thống
  Future<UserEntity> updateProfile({required String fullName});

  // Cập nhật avatar của người dùng lên hệ thống
  Future<UserEntity> updateAvatar({required File imageFile});

  // Đổi mật khẩu của người dùng
  Future<void> changePassword({required String oldPassword, required String newPassword,required String confirmPassword});
  
  // Đăng xuất tất cả các thiết bị
  Future<void> logoutAllDevices();

  // Xóa tài khoản
  Future<void> deleteAccount();
}