import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/features/auth/data/models/login_request_dto.dart';
import 'package:expense_management/features/auth/data/models/register_request_dto.dart';
import 'package:expense_management/features/auth/data/models/social_auth_models.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api_service.g.dart';


@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio ) = _AuthApiService;

  @POST(ApiEndpoints.login)
  Future<AuthResponseDto> login(@Body() LoginRequestDto params);

  @POST(ApiEndpoints.register)
  Future<BaseResponseDto<dynamic>> register(@Body() RegisterRequestDto params);

  @GET(ApiEndpoints.profile)
  Future<BaseResponseDto<UserDataDto>> getFreshProfile(@Query("user_id") String userId);

  @POST(ApiEndpoints.socialLogin)
  Future<SocialAuthResponse> loginWithSocial(@Body() SocialLoginRequest request);

  @POST(ApiEndpoints.linkSocial)
  Future<AuthResponseDto> confirmLinkSocial(@Body() LinkSocialRequest request);

  @POST(ApiEndpoints.forgotPassword)
  Future<BaseResponseDto<void>> forgotPassword(
    @Field("email") String email,
  );
}