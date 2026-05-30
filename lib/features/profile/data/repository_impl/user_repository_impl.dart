import 'package:dio/dio.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/core/database/app_database.dart' as db;
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasource/remote/user_api_service.dart';
import '../mappers/profile_mapper.dart';

class UserRepositoryImpl implements UserRepository {
  final UserApiService _userApiService;
  final db.AppDatabase _db;
  final SecureStorageService _secureStorageService;

  UserRepositoryImpl(this._userApiService, this._db, this._secureStorageService);

  @override
  Future<UserEntity> updateProfile({required String fullName}) async {
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
      fullName: fullName,
    );
    await _db.saveUserProfile(updatedLocalRow);

    AppLogger.debug("💾 [SQLite] Cập nhật tạm thời tên mới: '$fullName' vào SQLite", tag: "SQLite");

    // 2. Đồng bộ thông tin lên Server
    try {
      final responseDto = await _userApiService.updateProfile(fullName);
      final freshData = responseDto.data;
      
      // Cập nhật lại cache cục bộ bằng dữ liệu chuẩn từ Backend trả về
      await _db.saveUserProfile(db.User(
        id: freshData.userId,
        email: freshData.email,
        fullName: freshData.profile.fullName,
        currency: freshData.preference.currency,
        language: freshData.preference.language,
        theme: freshData.preference.theme,
      ));
      
      AppLogger.debug("💾 [SQLite] Đã đồng bộ dữ liệu hồ sơ chuẩn từ BE vào SQLite thành công", tag: "SQLite");

      return ProfileMapper.toUserEntity(freshData);
    } on DioException catch (e) {
      // Ném lỗi ra ngoài để thông báo đồng bộ thất bại (dữ liệu vẫn được lưu tạm ở SQLite thiết bị)
      throw AppException(e.toNetworkFailure());
    }
  }
}