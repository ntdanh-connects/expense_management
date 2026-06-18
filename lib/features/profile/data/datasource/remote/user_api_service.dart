
import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/features/profile/data/models/preference_options_dto.dart';
import 'package:expense_management/features/profile/data/models/exchange_rates_dto.dart';
import 'package:expense_management/features/profile/data/models/user_session_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api_service.g.dart';

@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio) = _UserApiService;

  @POST(ApiEndpoints.updateProfile)
  Future<BaseResponseDto<UserDataDto>> updateProfile(
    @Field("full_name") String? fullName,
    @Field("language") String? language,
    @Field("currency") String? currency,
    @Field("timezone") String? timezone,
    @Field("theme") String? theme,
    @Field("financial_start_day") int? financialStartDay,
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

  @GET(ApiEndpoints.preferenceOptions)
  Future<BaseResponseDto<PreferenceOptionsDto>> getPreferenceOptions();

  @GET(ApiEndpoints.exchangeRates)
  Future<BaseResponseDto<ExchangeRatesDto>> getExchangeRates();

  @GET(ApiEndpoints.activeSessions)
  Future<BaseResponseDto<List<UserSessionDto>>> getActiveSessions();

  @DELETE(ApiEndpoints.revokeSession)
  Future<BaseResponseDto<void>> revokeSession(@Path("id") String id);
}
