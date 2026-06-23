import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/wallet/data/data_source/remote/qr_transfer_api_service.dart';
import 'package:expense_management/features/wallet/domain/repository/qr_transfer_repository.dart';

class QrTransferRepositoryImpl implements QrTransferRepository {
  final QrTransferApiService _apiService;

  QrTransferRepositoryImpl(this._apiService);

  @override
  Future<BaseResponseDto<dynamic>> decodeQrCode(String qrString) {
    return _apiService.decodeQr(qrString);
  }

  @override
  Future<BaseResponseDto<dynamic>> executeTransfer(Map<String, dynamic> payload) {
    return _apiService.transferQr(payload);
  }

  @override
  Future<BaseResponseDto<dynamic>> generateMyQrCode({
    String? walletId,
    double? amount,
    String? description,
  }) {
    return _apiService.generateMyQr(
      walletId: walletId,
      amount: amount,
      description: description,
    );
  }

  @override
  Future<BaseResponseDto<dynamic>> fetchPayees({
    String? search,
    int? perPage,
    int? page,
  }) {
    return _apiService.getPayees(
      search: search,
      perPage: perPage,
      page: page,
    );
  }

  @override
  Future<BaseResponseDto<dynamic>> removePayee(String id) {
    return _apiService.deletePayee(id);
  }
}
