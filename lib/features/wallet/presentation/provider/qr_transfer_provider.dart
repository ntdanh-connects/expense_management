import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import '../../data/data_source/remote/qr_transfer_api_service.dart';

// API Service provider
final qrTransferApiServiceProvider = Provider<QrTransferApiService>((ref) {
  final dio = ref.read(dioClientProvider);
  return QrTransferApiService(dio);
});

// StateNotifier for managing QR Transfer flows
class QrTransferNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final QrTransferApiService _apiService;

  QrTransferNotifier(this._apiService) : super(const AsyncValue.data(null));

  // Step 1: Decode QR string
  Future<Map<String, dynamic>?> decodeQrCode(String qrString) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.decodeQr(qrString);
      final mapData = response.data as Map<String, dynamic>?;
      state = AsyncValue.data(mapData);
      return mapData;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  // Step 2: Execute virtual transfer
  Future<Map<String, dynamic>?> executeTransfer({
    required String fromWalletId,
    required String payeeType,
    required double amount,
    String? notes,
    String? payeeUserId,
    String? bankCode,
    String? accountNumber,
    String? payeeName,
    String? toWalletId,
    String? categoryId,
  }) async {
    try {
      final payload = {
        'from_wallet_id': fromWalletId,
        'payee_type': payeeType,
        'amount': amount,
        if (notes != null) 'notes': notes,
        if (payeeUserId != null) 'payee_user_id': payeeUserId,
        if (bankCode != null) 'bank_code': bankCode,
        if (accountNumber != null) 'account_number': accountNumber,
        if (payeeName != null) 'payee_name': payeeName,
        if (toWalletId != null) 'to_wallet_id': toWalletId,
        if (categoryId != null) 'category_id': categoryId,
      };

      final response = await _apiService.transferQr(payload);
      return {
        'status': 'success',
        'message': response.message,
        'data': response.data,
      };
    } catch (e, stack) {
      AppLogger.error("🚨 [QR-Transfer] Exception during executeTransfer: $e\n$stack");
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Chuyển khoản thất bại',
            'data': data['data'],
          };
        }
      }
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Step 3: Generate My QR Code
  Future<Map<String, dynamic>?> generateMyQrCode({
    String? walletId,
    double? amount,
    String? description,
  }) async {
    try {
      final response = await _apiService.generateMyQr(
        walletId: walletId,
        amount: amount,
        description: description,
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Step 4: Fetch Saved Payees
  Future<Map<String, dynamic>?> fetchPayees({
    String? search,
    int? perPage,
    int? page,
  }) async {
    try {
      final response = await _apiService.getPayees(
        search: search,
        perPage: perPage,
        page: page,
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Step 5: Delete Saved Payee
  Future<bool> removePayee(String id) async {
    try {
      await _apiService.deletePayee(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Provider definition
final qrTransferProvider = StateNotifierProvider<QrTransferNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final apiService = ref.watch(qrTransferApiServiceProvider);
  return QrTransferNotifier(apiService);
});
