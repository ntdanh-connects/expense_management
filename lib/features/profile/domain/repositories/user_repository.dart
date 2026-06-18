import 'package:expense_management/features/profile/data/models/user_session_dto.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:expense_management/features/profile/data/models/preference_options_dto.dart';
import 'package:expense_management/features/profile/data/models/exchange_rates_dto.dart';

import 'dart:io';

abstract class UserRepository {
  /// Cập nhật thông tin hồ sơ của người dùng lên hệ thống
  Future<UserEntity> updateProfile({
    String? fullName,
    String? language,
    String? currency,
    String? timezone,
    String? theme,
  });

  // Cập nhật avatar của người dùng lên hệ thống
  Future<UserEntity> updateAvatar({required File imageFile});

  // Đổi mật khẩu của người dùng
  Future<void> changePassword({required String oldPassword, required String newPassword,required String confirmPassword});
  
  // Đăng xuất tất cả các thiết bị
  Future<void> logoutAllDevices();

  // Lấy các phiên đăng nhập đang hoạt động
  Future<List<UserSessionDto>> getActiveSessions();

  // Thu hồi một phiên đăng nhập cụ thể
  Future<void> revokeSession(String sessionId);

  // Xóa tài khoản
  Future<void> deleteAccount();

  // Lấy các tùy chọn tiền tệ và múi giờ hệ thống
  Future<PreferenceOptionsDto> getPreferenceOptions();

  // Lấy tỷ giá hối đoái mới nhất
  Future<ExchangeRatesDto> getExchangeRates();
}