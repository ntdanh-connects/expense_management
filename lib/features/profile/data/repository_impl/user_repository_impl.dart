import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/core/network/network_failure.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/core/database/app_database.dart' as db;
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasource/remote/user_api_service.dart';
import '../mappers/profile_mapper.dart';

class UserRepositoryImpl implements UserRepository {
  final UserApiService _userApiService;
  final db.AppDatabase _db;
  final SecureStorageService _secureStorageService;

  UserRepositoryImpl(this._userApiService, this._db, this._secureStorageService);

  @override
  Future<UserEntity> updateProfile({String? fullName, String? language}) async {
    final userId = await _secureStorageService.get(key: AppConstant.userId);
    if (userId == null) {
      throw Exception("Không tìm thấy thông tin định danh người dùng.");
    }

    final currentLocalRow = await _db.getUserProfile(userId);
    if (currentLocalRow == null) {
      throw Exception("Không tìm thấy thông tin hồ sơ lưu trữ cục bộ.");
    }

    // 1. Cập nhật Drift SQLite trước để giao diện (UI) cập nhật ngay lập tức
    final updatedLocalRow = currentLocalRow.copyWith(
      fullName: fullName ?? currentLocalRow.fullName,
      language: language ?? currentLocalRow.language,
    );
    await _db.saveUserProfile(updatedLocalRow);

    AppLogger.info("💾 [SQLite] [Offline-First] Cập nhật SQLite thành công! Đã lưu tạm thời: fullName='${fullName ?? currentLocalRow.fullName}', language='${language ?? currentLocalRow.language}'.", tag: "SQLite");
    AppLogger.debug("🌐 [Sync-Flow] Bắt đầu gửi đồng bộ thông tin mới lên Server...", tag: "Sync-Flow");

    // 2. Đồng bộ thông tin lên Server
    try {
      final responseDto = await _userApiService.updateProfile(
        fullName ?? currentLocalRow.fullName,
        language ?? currentLocalRow.language,
      );
      final freshData = responseDto.data;
      
      // Cập nhật lại cache cục bộ bằng dữ liệu chuẩn từ Backend trả về
      await _db.saveUserProfile(db.User(
        id: freshData.userId,
        email: freshData.email,
        fullName: freshData.profile.fullName,
        avatarUrl: freshData.profile.avatarUrl,
        currency: freshData.preference.currency,
        language: freshData.preference.language,
        theme: freshData.preference.theme,
      ));
      
      AppLogger.info("☁️ [Sync-Flow] Kiểm tra Server: Đồng bộ thành công! Đã cập nhật đè dữ liệu chuẩn từ BE vào SQLite local.", tag: "Sync-Flow");

      return ProfileMapper.toUserEntity(freshData);
    } on DioException catch (e) {
      final errorMsg = e.message ?? "Lỗi mạng kết nối";
      AppLogger.warning("⚠️ [Sync-Flow] Kiểm tra Server: Đồng bộ thất bại ($errorMsg). Giữ tên tạm thời '$fullName' trong SQLite local để chạy offline.", tag: "Sync-Flow");
      throw AppException(e.toNetworkFailure());
    } on CheckedFromJsonException catch (e, stackTrace) {
      AppLogger.error(
        "🚨 [JSON-Parse] Lỗi phân tích cú pháp JSON khi cập nhật Profile! "
        "Class: '${e.className}', Key lỗi: '${e.key}' (Giá trị thực tế: ${e.map?[e.key]}, Lỗi: ${e.message})",
        tag: "JSON-Parse",
        stackTrace: stackTrace,
      );
      throw AppException(NetworkFailure.unknown(message: "Lỗi cấu trúc dữ liệu JSON từ Server ở trường '${e.key}'"));
    }
  }

  @override
  Future<UserEntity> updateAvatar({required File imageFile}) async {
    final userId = await _secureStorageService.get(key: AppConstant.userId);
    if (userId == null) {
      throw Exception("Không tìm thấy thông tin định danh người dùng.");
    }

    try {

      final file = imageFile.path.split('/').last;
      final extension = file.split('.').last.toLowerCase();
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: file,
        contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
      );
      // 1. Gọi API gửi file ảnh lên AWS S3 (thông qua Backend)
      final responseDto = await _userApiService.updateAvatar(multipartFile);
      final freshData = responseDto.data;
      
      // 2. Lưu thông tin (đường dẫn ảnh mới) vào SQLite cục bộ để UI tự động đổi
      await _db.saveUserProfile(db.User(
        id: freshData.userId,
        email: freshData.email,
        fullName: freshData.profile.fullName,
        avatarUrl: freshData.profile.avatarUrl,
        currency: freshData.preference.currency,
        language: freshData.preference.language,
        theme: freshData.preference.theme,
      ));
      
      return ProfileMapper.toUserEntity(freshData);
    } on DioException catch (e) {
      AppLogger.error(
        "Dio Error khi upload ảnh: ${e.message}", 
        tag: "AVATAR_API_ERROR", 
        details: e.response?.data 
      );
      throw AppException(e.toNetworkFailure());
    }catch (e, stack) {
      AppLogger.error(
        "Lỗi không mong muốn: ${e.toString()}", 
        tag: "AVATAR_CRITICAL_ERROR", 
        stackTrace: stack
      );
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _userApiService.changePassword({
        'current_password': oldPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMessage = "Đổi mật khẩu thất bại. Vui lòng thử lại sau.";
      
      if (errorData != null && errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
      }
      
      AppLogger.error(
        "Dio Error khi đổi mật khẩu: ${e.message}",
        tag: "CHANGE_PASSWORD_API_ERROR",
        details: errorData,
      );
      
      throw Exception(errorMessage);
    } catch (e, stack) {
      AppLogger.error(
        "Lỗi không mong muốn khi đổi mật khẩu: ${e.toString()}",
        tag: "CHANGE_PASSWORD_CRITICAL_ERROR",
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> logoutAllDevices() async {
    try {
      await _userApiService.logoutAll();
    } on DioException catch (e) {
      AppLogger.error(
        "Dio Error khi logout tất cả thiết bị: ${e.message}", 
        tag: "LOGOUT_ALL_API_ERROR", 
        details: e.response?.data 
      );
      throw Exception(e.response?.data['message'] ?? "Không thể đăng xuất các thiết bị khác.");
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _userApiService.deleteAccount(); 
    } on DioException catch (e) {
      AppLogger.error(
        "Dio Error khi xóa tài khoản: ${e.message}", 
        tag: "DELETE_ACCOUNT_API_ERROR", 
        details: e.response?.data 
      );
      throw Exception(e.response?.data['message'] ?? "Xóa tài khoản thất bại!");
    } catch (e, stack) {
      AppLogger.error(
        "Lỗi hệ thống khi xóa tài khoản: ${e.toString()}", 
        tag: "DELETE_ACCOUNT_CRITICAL_ERROR", 
        stackTrace: stack
      );
      rethrow;
    }
  }
}