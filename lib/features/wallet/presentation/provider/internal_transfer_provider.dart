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
      return 'Vui lòng chọn đầy đủ Ví nguồn và Ví đích!';
    }
    if (fromWallet.id == toWallet.id) {
      return 'Ví nguồn và Ví đích không được trùng nhau!';
    }
    if (amountStr.isEmpty) {
      return 'Vui lòng nhập số tiền cần chuyển!';
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return 'Số tiền chuyển không hợp lệ!';
    }

    if (fromWallet.balance < amount) {
      return 'Số dư ví "${fromWallet.name}" không đủ!';
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
