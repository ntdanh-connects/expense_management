import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api_service.g.dart';

@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio) = _UserApiService;

  @PUT(ApiEndpoints.updateProfile) 
  Future<BaseResponseDto<UserDataDto>> updateProfile(@Field("full_name") String fullName);
}