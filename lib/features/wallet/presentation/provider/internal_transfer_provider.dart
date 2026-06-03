import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/entities/internal_transfer_record.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:flutter_riverpod/legacy.dart';

class InternalTransferHistoryNotifier extends StateNotifier<List<InternalTransferRecord>> {
  final WalletRepository _repository;

  InternalTransferHistoryNotifier(this._repository) : super([]) {
    fetchTransferHistory();
  }

  Future<void> fetchTransferHistory() async {
    try {
      final history = await _repository.getTransferHistory();
      state = history;
    } catch (e, stack) {
      AppLogger.error("🚨 [Transfer-History] Lỗi tải lịch sử chuyển tiền: $e", tag: "Transfer-History", stackTrace: stack);
    }
  }

  Future<String?> executeTransfer({
    required WalletEntity? fromWallet,
    required WalletEntity? toWallet,
    required String amountStr,
  }) async {
    if (fromWallet == null || toWallet == null) {
      return 'select_source_dest_wallet_error';
    }
    if (fromWallet.id == toWallet.id) {
      return 'same_wallet_error';
    }
    if (amountStr.isEmpty) {
      return 'enter_amount_error';
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return 'invalid_amount_error';
    }

    if (fromWallet.balance < amount) {
      return 'insufficient_balance_error';
    }

    try {
      await _repository.transferMoney(
        fromWalletId: fromWallet.id,
        toWalletId: toWallet.id,
        amount: amount,
      );

      final newRecord = InternalTransferRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromWalletName: fromWallet.name,
        toWalletName: toWallet.name,
        amount: amount,
        date: DateTime.now(),
      );
      state = [newRecord, ...state];
      return null; // Thành công
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}

final internalTransferHistoryProvider =
    StateNotifierProvider<InternalTransferHistoryNotifier, List<InternalTransferRecord>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return InternalTransferHistoryNotifier(repository);
});
