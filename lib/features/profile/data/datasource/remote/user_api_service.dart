import 'dart:io';

import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api_service.g.dart';

@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio) = _UserApiService;

  @POST(ApiEndpoints.updateProfile)
  Future<BaseResponseDto<UserDataDto>> updateProfile(
    @Field("full_name") String? fullName,
    @Field("language") String? language,
  );

  @POST(ApiEndpoints.updateAvatar)
  @MultiPart()
  Future<BaseResponseDto<UserDataDto>> updateAvatar(
    @Part(name: "avatar") MultipartFile avatar
  );

  @POST(ApiEndpoints.logout)
  Future<BaseResponseDto<void>> logout();

  @POST(ApiEndpoints.logoutAll)
  Future<BaseResponseDto<void>> logoutAll();

  @POST(ApiEndpoints.changePassword)
  Future<BaseResponseDto<void>> changePassword(@Body() Map<String, dynamic> body);

  @DELETE(ApiEndpoints.deleteAccount)
  Future<BaseResponseDto<void>> deleteAccount();
}
