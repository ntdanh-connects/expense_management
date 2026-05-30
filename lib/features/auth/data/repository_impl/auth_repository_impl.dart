

import 'package:dio/dio.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/core/network/network_failure.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/data/datasource/local/auth_local_data_source.dart';
import 'package:expense_management/features/auth/data/datasource/remote/auth_api_service.dart';
import 'package:expense_management/features/auth/data/mappers/auth_mapper.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/features/auth/data/models/login_request_dto.dart';
import 'package:expense_management/features/auth/data/models/register_request_dto.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/database/app_database.dart' as db;

class AuthRepositoryImpl implements AuthRepository{
  final AuthApiService _authApiService;
  final SecureStorageService _secureStorageService;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._authApiService,this._secureStorageService,this._localDataSource);

  @override
  Future<UserEntity> loginWithEmailPassword(String email, String password) async{
    AppLogger.debug("🌐 [Auth] Đang gửi yêu cầu đăng nhập cho tài khoản '$email' lên Remote Server...", tag: "Auth");
    try{
      final requestParams = LoginRequestDto(email: email, password: password);

      final dto = await _authApiService.login(requestParams);
      AppLogger.info("☁️ [Auth] Đăng nhập thành công! Đã lấy Tokens cho User ID: ${dto.data.userId}.", tag: "Auth");

      await _secureStorageService.save(key: AppConstant.accessToken, value: dto.accessToken);
      await _secureStorageService.save(key: AppConstant.refreshToken, value: dto.refreshToken);
      await _secureStorageService.save(key: AppConstant.userId, value: dto.data.userId);

      await _localDataSource.cacheProfile(db.User(id: dto.data.userId,
          email: dto.data.email,
          fullName: dto.data.profile.fullName,
          currency: dto.data.preference.currency,
          language: dto.data.preference.language,
          theme: dto.data.preference.theme,));

      AppLogger.info("💾 [SQLite] Đã lưu cache hồ sơ đăng nhập cục bộ cho User ID: ${dto.data.userId} thành công!", tag: "SQLite");

      return AuthMapper.toUserEntity(dto.data);
    }on DioException catch(e, stackTrace){
      AppLogger.error("🚨 [Auth] Đăng nhập thất bại từ Remote Server: ${e.message}", tag: "Auth", stackTrace: stackTrace);
      throw AppException(e.toNetworkFailure());
    } on CheckedFromJsonException catch (e, stackTrace) {
      AppLogger.error(
        "🚨 [JSON-Parse] Lỗi phân tích cú pháp JSON khi Đăng nhập! "
        "Class: '${e.className}', Key lỗi: '${e.key}' (Giá trị thực tế: ${e.map?[e.key]}, Lỗi: ${e.message})",
        tag: "JSON-Parse",
        stackTrace: stackTrace,
      );
      throw AppException(NetworkFailure.unknown(message: "Lỗi cấu trúc dữ liệu JSON từ Server ở trường '${e.key}'"));
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SQLite] Lỗi lưu cache hồ sơ đăng nhập cục bộ: $e", tag: "SQLite", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserEntity> syncFreshProfile() async {
    AppLogger.debug("🌐 [Auth-Sync] Bắt đầu đồng bộ tải hồ sơ người dùng mới nhất từ Remote Server...", tag: "Auth-Sync");
    try {
      final userId = await _secureStorageService.get(key: AppConstant.userId);
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin định danh người dùng cục bộ.");
      }

      final response = await _authApiService.getFreshProfile(userId); 
      final freshData = response.data;
      AppLogger.info("☁️ [Auth-Sync] Tải hồ sơ User ID: $userId từ Server thành công! Tiến hành ghi đè SQLite local...", tag: "Auth-Sync");

      // Ghi đè cập nhật SQLite Local bằng dữ liệu chuẩn nhất từ Backend ní trả về
      await _localDataSource.cacheProfile(db.User(
        id: freshData.userId,
        email: freshData.email,
        fullName: freshData.profile.fullName,
        currency: freshData.preference.currency,
        language: freshData.preference.language,
        theme: freshData.preference.theme,
      ));

      AppLogger.info("💾 [SQLite] Đồng bộ ghi đè hồ sơ User ID: $userId vào SQLite local thành công!", tag: "SQLite");

      return AuthMapper.toUserEntity(freshData);
    } on DioException catch (e, stackTrace) {
      AppLogger.error("🚨 [Auth-Sync] Lỗi đồng bộ tải hồ sơ từ Remote Server: ${e.message}", tag: "Auth-Sync", stackTrace: stackTrace);
      throw AppException(e.toNetworkFailure());
    } on CheckedFromJsonException catch (e, stackTrace) {
      AppLogger.error(
        "🚨 [JSON-Parse] Lỗi phân tích cú pháp JSON khi đồng bộ Profile! "
        "Class: '${e.className}', Key lỗi: '${e.key}' (Giá trị thực tế: ${e.map?[e.key]}, Lỗi: ${e.message})",
        tag: "JSON-Parse",
        stackTrace: stackTrace,
      );
      throw AppException(NetworkFailure.unknown(message: "Lỗi cấu trúc dữ liệu JSON từ Server ở trường '${e.key}'"));
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SQLite] Lỗi ghi đè hồ sơ vào SQLite local: $e", tag: "SQLite", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<dynamic> registerWithEmail(String fullName, String email, String password) async{
    try{
    final requestParams = RegisterRequestDto(fullName: fullName, email: email, password: password,passwordConfirmation: password);
    final response = await _authApiService.register(requestParams);
    return response.message;
    }on DioException catch (e){
      throw AppException(e.toNetworkFailure());
    }
  }

}