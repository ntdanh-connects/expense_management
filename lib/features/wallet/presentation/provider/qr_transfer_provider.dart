import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/core/error/error_handler_mixin.dart';
import 'package:expense_management/features/wallet/domain/repository/qr_transfer_repository.dart';
import 'package:expense_management/features/wallet/domain/di/domain_providers.dart';

// StateNotifier for managing QR Transfer flows
class QrTransferNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> with ErrorHandlerMixin {
  final QrTransferRepository _repository;

  QrTransferNotifier(this._repository) : super(const AsyncValue.data(null));

  // Step 1: Decode QR string
  Future<Map<String, dynamic>?> decodeQrCode(String qrString) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.decodeQrCode(qrString);
      final mapData = response.data as Map<String, dynamic>?;
      state = AsyncValue.data(mapData);
      return mapData;
    } catch (e, stack) {
      logException(e, stack, tag: 'QrTransferNotifier_decodeQrCode');
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
    bool? isQr,
    String? transactionDate,
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
        if (isQr != null) 'is_qr': isQr,
        if (transactionDate != null) 'transaction_date': transactionDate,
      };

      final response = await _repository.executeTransfer(payload);
      return {
        'status': 'success',
        'message': response.message,
        'data': response.data,
      };
    } catch (e, stack) {
      logException(e, stack, tag: 'QrTransferNotifier_executeTransfer');
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
      final response = await _repository.generateMyQrCode(
        walletId: walletId,
        amount: amount,
        description: description,
      );
      return response.data as Map<String, dynamic>?;
    } catch (e, stack) {
      logException(e, stack, tag: 'QrTransferNotifier_generateMyQrCode');
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
      final response = await _repository.fetchPayees(
        search: search,
        perPage: perPage,
        page: page,
      );
      return response.data as Map<String, dynamic>?;
    } catch (e, stack) {
      logException(e, stack, tag: 'QrTransferNotifier_fetchPayees');
      return null;
    }
  }

  // Step 5: Delete Saved Payee
  Future<bool> removePayee(String id) async {
    try {
      await _repository.removePayee(id);
      return true;
    } catch (e, stack) {
      logException(e, stack, tag: 'QrTransferNotifier_removePayee');
      return false;
    }
  }
}

// Provider definition
final qrTransferProvider = StateNotifierProvider<QrTransferNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final repository = ref.watch(qrTransferRepositoryProvider);
  return QrTransferNotifier(repository);
});
