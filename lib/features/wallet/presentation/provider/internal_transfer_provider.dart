import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/entities/internal_transfer_record.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/profile/user_provider.dart';

class InternalTransferHistoryNotifier extends StateNotifier<AsyncValue<List<InternalTransferRecord>>> {
  final WalletRepository _repository;
  final Ref _ref;

  InternalTransferHistoryNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        fetchTransferHistory();
      }
    });
  }

  Future<void> fetchTransferHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _repository.getTransferHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      AppLogger.error("🚨 [Transfer-History] Lỗi tải lịch sử chuyển tiền: $e", tag: "Transfer-History", stackTrace: stack);
      state = AsyncValue.error(e, stack);
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

    final timezone = _ref.read(currentUserProvider)?.timezone;

    try {
      await _repository.transferMoney(
        fromWalletId: fromWallet.id,
        toWalletId: toWallet.id,
        amount: amount,
        timezone: timezone,
      );

      final newRecord = InternalTransferRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromWalletName: fromWallet.name,
        toWalletName: toWallet.name,
        amount: amount,
        date: DateTime.now(),
        timezone: timezone,
        currencyCode: fromWallet.currencyCode,
      );
      state = AsyncValue.data([newRecord, ...(state.value ?? [])]);
      return null; // Thành công
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}

final internalTransferHistoryProvider =
    StateNotifierProvider<InternalTransferHistoryNotifier, AsyncValue<List<InternalTransferRecord>>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return InternalTransferHistoryNotifier(repository, ref);
});
