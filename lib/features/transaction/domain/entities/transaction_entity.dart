class TransactionEntity {
  final String id;
  final String walletId;
  final String? categoryId;
  final String type; // income, expense
  final String status;
  final double amount;
  final String? currencyCode;
  final double? exchangeRate;
  final String title;
  final String? notes;
  final String? timezone;
  final String? sourceType;
  final DateTime transactionDate;
  
  // Custom helper fields populated from joins
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? walletName;
  final String? walletIcon;
  final String? walletColor;
  final List<String> attachmentUrls;

  TransactionEntity({
    required this.id,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.status,
    required this.amount,
    this.currencyCode,
    this.exchangeRate,
    required this.title,
    this.notes,
    this.timezone,
    this.sourceType,
    required this.transactionDate,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.walletName,
    this.walletIcon,
    this.walletColor,
    this.attachmentUrls = const [],
  });

  bool get isIncome => type == 'income';
}
