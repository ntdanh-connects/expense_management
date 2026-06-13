import 'dart:io';

class TransactionParams {
  final String walletId;
  final String walletName;
  final String categoryId;
  final String categoryName;
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

  TransactionParams({
    required this.walletId,
    required this.walletName,
    required this.categoryId,
    required this.categoryName,
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
  });
}
