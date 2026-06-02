import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_riverpod/legacy.dart';

class InternalTransferRecord {
  final String id;
  final String fromWalletName;
  final String toWalletName;
  final double amount;
  final DateTime date;

  InternalTransferRecord({
    required this.id,
    required this.fromWalletName,
    required this.toWalletName,
    required this.amount,
    required this.date,
  });
}

class InternalTransferHistoryNotifier extends StateNotifier<List<InternalTransferRecord>> {
  InternalTransferHistoryNotifier() : super([]);

  String? executeTransfer({
    required WalletEntity? fromWallet,
    required WalletEntity? toWallet,
    required String amountStr,
  }) {
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

    final newRecord = InternalTransferRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromWalletName: fromWallet.name,
      toWalletName: toWallet.name,
      amount: amount,
      date: DateTime.now(),
    );
    state = [newRecord, ...state];
    return null; // Thành công
  }
}

final internalTransferHistoryProvider =
    StateNotifierProvider<InternalTransferHistoryNotifier, List<InternalTransferRecord>>((ref) {
  return InternalTransferHistoryNotifier();
});
