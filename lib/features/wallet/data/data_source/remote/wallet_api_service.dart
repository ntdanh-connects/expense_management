import 'package:dio/dio.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/wallet/data/models/wallet_dto.dart';
import 'package:retrofit/retrofit.dart';
import 'package:expense_management/core/network/api_endpoints.dart';

part 'wallet_api_service.g.dart';

@RestApi()
abstract class WalletApiService {
  factory WalletApiService(Dio dio) = _WalletApiService;

  @GET(ApiEndpoints.wallets)
  Future<BaseResponseDto<List<WalletDto>>> getRemoteWallets(
    @Query("user_id") String userId,
  );
}