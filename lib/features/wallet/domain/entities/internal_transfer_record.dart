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
