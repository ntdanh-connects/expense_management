import 'package:dio/dio.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/data/models/wallet_dto.dart';
import 'package:retrofit/retrofit.dart';
import 'package:expense_management/core/network/api_endpoints.dart';

part 'wallet_api_service.g.dart';

@RestApi()
abstract class WalletApiService {
  factory WalletApiService(Dio dio) = _WalletApiService;

  @GET(ApiEndpoints.wallets)
  Future<BaseResponseDto<List<WalletDto>>> getRemoteWallets();

  @POST(ApiEndpoints.wallets)
  Future<BaseResponseDto<WalletDto>> createRemoteWallet(@Body() CreateWalletRequest request);

  @POST('${ApiEndpoints.wallets}/{id}')
  Future<BaseResponseDto<WalletDto>> updateRemoteWallet(
    @Path('id') String id,
    @Body() CreateWalletRequest request,
  );

  @POST('${ApiEndpoints.wallets}/{id}/set-default-receiving')
  Future<BaseResponseDto<dynamic>> setDefaultReceivingWallet(
    @Path('id') String id,
  );

  @POST(ApiEndpoints.transfer)
  Future<BaseResponseDto<dynamic>> transferMoney(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.transfers)
  Future<BaseResponseDto<List<dynamic>>> getTransfers();
}