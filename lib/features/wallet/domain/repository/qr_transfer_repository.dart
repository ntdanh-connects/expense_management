import 'package:expense_management/core/network/base_response_dto.dart';

abstract class QrTransferRepository {
  Future<BaseResponseDto<dynamic>> decodeQrCode(String qrString);
  
  Future<BaseResponseDto<dynamic>> executeTransfer(Map<String, dynamic> payload);
  
  Future<BaseResponseDto<dynamic>> generateMyQrCode({
    String? walletId,
    double? amount,
    String? description,
  });
  
  Future<BaseResponseDto<dynamic>> fetchPayees({
    String? search,
    int? perPage,
    int? page,
  });
  
  Future<BaseResponseDto<dynamic>> removePayee(String id);
}
