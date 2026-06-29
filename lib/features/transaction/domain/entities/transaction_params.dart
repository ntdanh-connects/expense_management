
class TransactionParams {
  final String walletId;
  final String walletName;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'income' hoặc 'expense'
  final double amount;
  final String title;
  final String? notes;
  final String transactionDate;
  final String currencyCode;
  final double exchangeRate;
  final String timezone;
  final String? attachmentPath; // Đường dẫn file ảnh biên nhận lưu tạm để upload
  final String? payeeId;
  final String? payeeName;
  final String? payeeAccountNumber;
  final String? payeeBankName;
  final String? sourceType;
  final String? sourceId;

  TransactionParams({
    required this.walletId,
    required this.walletName,
    this.categoryId,
    this.categoryName,
    required this.type,
    required this.amount,
    required this.title,
    this.notes,
    required this.transactionDate,
    required this.currencyCode,
    required this.exchangeRate,
    required this.timezone,
    this.attachmentPath,
    this.payeeId,
    this.payeeName,
    this.payeeAccountNumber,
    this.payeeBankName,
    this.sourceType,
    this.sourceId,
  });
}
