import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/core/network/api_endpoints.dart';

part 'qr_transfer_api_service.g.dart';

@RestApi()
abstract class QrTransferApiService {
  factory QrTransferApiService(Dio dio) = _QrTransferApiService;

  @POST(ApiEndpoints.qrDecode)
  Future<BaseResponseDto<dynamic>> decodeQr(
    @Field('qr_string') String qrString,
  );

  @GET(ApiEndpoints.qrGenerateMyQr)
  Future<BaseResponseDto<dynamic>> generateMyQr({
    @Query('wallet_id') String? walletId,
    @Query('amount') double? amount,
    @Query('description') String? description,
  });

  @POST(ApiEndpoints.qrTransfer)
  Future<BaseResponseDto<dynamic>> transferQr(
    @Body() Map<String, dynamic> body,
  );

  @GET(ApiEndpoints.payees)
  Future<BaseResponseDto<dynamic>> getPayees({
    @Query('search') String? search,
    @Query('per_page') int? perPage,
    @Query('page') int? page,
  });

  @DELETE('${ApiEndpoints.deletePayee}/{id}')
  Future<BaseResponseDto<dynamic>> deletePayee(
    @Path('id') String id,
  );
}
