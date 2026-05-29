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

  void addTransfer({
    required String fromWalletName,
    required String toWalletName,
    required double amount,
  }) {
    final newRecord = InternalTransferRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromWalletName: fromWalletName,
      toWalletName: toWalletName,
      amount: amount,
      date: DateTime.now(),
    );
    state = [newRecord, ...state];
  }
}

final internalTransferHistoryProvider =
    StateNotifierProvider<InternalTransferHistoryNotifier, List<InternalTransferRecord>>((ref) {
  return InternalTransferHistoryNotifier();
});
